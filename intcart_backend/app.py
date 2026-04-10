from fastapi import FastAPI
from fastapi.staticfiles import StaticFiles
from fastapi.middleware.cors import CORSMiddleware
import numpy as np
import pickle
import json
import faiss
import os
import random
import re
import math
from collections import Counter
from gensim.models import Word2Vec

app = FastAPI()

# -------------------------------
# CORS
# -------------------------------
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# -------------------------------
# BASE DIR
# -------------------------------
BASE_DIR = os.path.dirname(os.path.abspath(__file__))

# -------------------------------
# SERVE IMAGES
# -------------------------------
app.mount("/images", StaticFiles(directory=os.path.join(BASE_DIR, "images")), name="images")

# -------------------------------
# LOAD DATA
# -------------------------------
index = faiss.read_index(os.path.join(BASE_DIR, "data/faiss.index"))

with open(os.path.join(BASE_DIR, "data/id_map.pkl"), "rb") as f:
    id_map = pickle.load(f)

with open(os.path.join(BASE_DIR, "data/products.json")) as f:
    products = json.load(f)

with open(os.path.join(BASE_DIR, "data/image_embeddings.pkl"), "rb") as f:
    image_embeddings = pickle.load(f)

model = Word2Vec.load(os.path.join(BASE_DIR, "data/item2vec.model"))

print("✅ Loaded products:", len(products))
print("✅ Loaded image embeddings:", len(image_embeddings))


# -------------------------------
# GROUP BY TYPE
# -------------------------------
type_to_products = {}
for pid, data in products.items():
    t = data["type"]
    type_to_products.setdefault(t, []).append(pid)


# -------------------------------
# HELPERS
# -------------------------------
def cosine(a, b):
    return np.dot(a, b) / (np.linalg.norm(a) * np.linalg.norm(b))


def resolve_item(name):
    if name in products:
        return name
    matches = [k for k in products.keys() if k.startswith(name)]
    return matches[0] if matches else None


def pick_best_product(product_list):
    return sorted(product_list, key=lambda x: products[x]["price"])[0]


# removed get_image_path because we read true frontend image paths from products.json directly


def format_items(items):
    res = []

    for item in items:
        if item not in products:
            continue

        res.append({
            "id": item,
            "name": products[item].get("name", products[item]["type"]),
            "type": products[item]["type"],
            "category": products[item]["category"],
            "price": products[item]["price"],
            "image": products[item].get("image", "/images/default.jpg")
        })

    return res


# -------------------------------
# RULES
# -------------------------------
bundle_rules = {
    "pan": ["spatula", "pot", "knife"],
    "knife": ["cutting_board", "pan"],
    "table": ["chair", "plate"],
    "sofa": ["coffee_table"]
}


# -------------------------------
# MAIN API
# -------------------------------
@app.post("/recommend")
def recommend(cart: list[str]):

    cart = [resolve_item(i) for i in cart]
    cart = [i for i in cart if i is not None]

    if not cart:
        return {"error": "No valid items"}

    cart_category = products[cart[0]]["category"]
    cart_types = [products[i]["type"] for i in cart]

    # -------------------------------
    # EMBEDDINGS
    # -------------------------------
    text_vecs = [model.wv[i] for i in cart if i in model.wv]
    text_query = np.mean(text_vecs, axis=0)

    image_vecs = [image_embeddings[i] for i in cart if i in image_embeddings]
    image_query = np.mean(image_vecs, axis=0) if image_vecs else None

    # -------------------------------
    # FAISS SEARCH
    # -------------------------------
    D, I = index.search(np.array([text_query]), k=30)
    candidates = [id_map[i] for i in I[0]]

    # -------------------------------
    # SCORE + FILTER
    # -------------------------------
    type_scores = {}

    for item in candidates:

        if item not in products:
            continue

        # HARD CATEGORY FILTER
        if products[item]["category"] != cart_category:
            continue

        t = products[item]["type"]

        if t in cart_types:
            continue

        score = cosine(text_query, model.wv[item])

        # category boost
        score += 0.5

        # image boost
        if image_query is not None and item in image_embeddings:
            score += 0.3 * cosine(image_query, image_embeddings[item])

        if t not in type_scores or score > type_scores[t][1]:
            type_scores[t] = (item, score)

    # -------------------------------
    # FBT
    # -------------------------------
    fbt = []
    used_types = set()

    for item in cart:
        t = products[item]["type"]

        if t in bundle_rules:
            for rel_type in bundle_rules[t]:

                if rel_type in used_types:
                    continue

                if rel_type in type_to_products:
                    fbt.append(pick_best_product(type_to_products[rel_type]))
                    used_types.add(rel_type)

                if len(fbt) >= 3:
                    break

    # -------------------------------
    # BUNDLE
    # -------------------------------
    bundle = []

    for t, (pid, score) in sorted(type_scores.items(), key=lambda x: x[1][1], reverse=True):
        bundle.append(pid)
        if len(bundle) >= 5:
            break

    # -------------------------------
    # SIMILAR
    # -------------------------------
    similar = []

    for t in cart_types:
        if t in type_to_products:
            similar.append(pick_best_product(type_to_products[t]))

    # -------------------------------
    # TITLES
    # -------------------------------
    if cart_category == "cookware":
        bundle_title = "Complete your cooking setup"
    elif cart_category == "furniture":
        bundle_title = "Complete your living room"
    else:
        bundle_title = "Complete your setup"

    # -------------------------------
    # RESPONSE
    # -------------------------------
    return {
        "sections": [
            {
                "title": "Frequently bought together",
                "items": format_items(fbt)
            },
            {
                "title": bundle_title,
                "items": format_items(bundle)
            },
            {
                "title": "Similar items",
                "items": format_items(similar)
            }
        ]
    }


# -------------------------------
# SKUs CATALOGUE
# -------------------------------
@app.get("/skus")
def get_skus():
    skus_path = os.path.join(BASE_DIR, "mock-api", "responses", "skus.json")
    with open(skus_path, "r", encoding="utf-8") as f:
        return json.load(f)


# -------------------------------
# AI SMART FILTERS
# -------------------------------
@app.get("/smart_filters")
def smart_filters(query: str):
    q_lower = query.lower().strip()
    
    # 1. Match products
    matched_pids = []
    for pid, p in products.items():
        name = p.get("name", "").lower()
        typ = p.get("type", "").lower()
        cat = p.get("category", "").lower()
        if q_lower in name or q_lower in typ or q_lower in cat:
            matched_pids.append(pid)
            
    if not matched_pids:
        return {"suggestedFilters": []}
        
    # 2. Extract Terms (Types, Prices, Attributes)
    prices = []
    types_map = {}
    words_map = {}
    
    STOPWORDS = {"and", "or", "the", "with", "set", "of", "for", "in", "a", "an", "to", "inch"}
    
    for pid in matched_pids:
        p = products[pid]
        
        t = p.get("type", "")
        if t:
            types_map.setdefault(t, []).append(pid)
            
        if p.get("price") is not None:
             prices.append(p["price"])
             
        name = p.get("name", "").lower()
        name = re.sub(r'[^\w\s-]', '', name)
        for tok in name.split():
            tok = tok.strip()
            if tok not in STOPWORDS and len(tok) > 2 and tok != q_lower:
                words_map.setdefault(tok, []).append(pid)

    # 3. Embedding-Based Scoring
    query_vecs = [model.wv[pid] for pid in matched_pids if pid in model.wv]
    query_centroid = np.mean(query_vecs, axis=0) if query_vecs else None
        
    scored_filters = []
    
    valid_words = [(w, pids) for w, pids in words_map.items() if len(pids) > 1]
    if not valid_words:
        valid_words = [(w, pids) for w, pids in words_map.items() if len(pids) > 0]
        
    for w, pids in valid_words:
        if query_centroid is not None:
            w_vecs = [model.wv[pid] for pid in pids if pid in model.wv]
            if w_vecs:
                w_centroid = np.mean(w_vecs, axis=0)
                score = cosine(query_centroid, w_centroid)
            else:
                score = 0.0
        else:
            score = len(pids) / len(matched_pids)
            
        scored_filters.append({
            "id": f"attr_{w}",
            "title": w.title().replace("-", " "),
            "type": "attribute",
            "score": float(score)
        })
        
    for t, pids in types_map.items():
        if t.lower() == q_lower: 
            continue
        if query_centroid is not None:
            t_vecs = [model.wv[pid] for pid in pids if pid in model.wv]
            if t_vecs:
                t_centroid = np.mean(t_vecs, axis=0)
                score = cosine(query_centroid, t_centroid) + 0.1 # slight boost
            else:
                score = 0.0
        else:
            score = len(pids) / len(matched_pids) + 0.1
            
        scored_filters.append({
            "id": f"type_{t}",
            "title": t.replace("_", " ").title(),
            "type": "category",
            "score": float(score)
        })
        
    scored_filters.sort(key=lambda x: x["score"], reverse=True)
    
    # 4. Extract Top ML-Ranked
    final_filters = []
    seen_titles = set()
    for f in scored_filters:
        if f["title"].lower() not in seen_titles:
            f.pop("score")
            final_filters.append(f)
            seen_titles.add(f["title"].lower())
        if len(final_filters) >= 5:
            break
            
    # 5. Price Bucketing
    if prices:
        prices.sort()
        median_price = prices[len(prices)//2]
        if median_price > 50:
            price_cap = int(math.ceil(median_price/10)*10)
            final_filters.append({
                "id": f"price_under_{price_cap}",
                "title": f"Under ${price_cap}",
                "type": "price"
            })
            
    return {"suggestedFilters": final_filters[:8]}
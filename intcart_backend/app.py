from fastapi import FastAPI
from fastapi.staticfiles import StaticFiles
from fastapi.middleware.cors import CORSMiddleware
import numpy as np
import pickle
import json
import faiss
import os
import random
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
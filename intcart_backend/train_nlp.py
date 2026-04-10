import json
import os
import pickle
import numpy as np
import faiss
from sentence_transformers import SentenceTransformer

BASE_DIR = os.path.dirname(os.path.abspath(__file__))

def main():
    print("Loading sentence-transformers Model...")
    model = SentenceTransformer("all-MiniLM-L6-v2")

    print("Loading products.json...")
    with open(os.path.join(BASE_DIR, "data/products.json")) as f:
        products = json.load(f)

    sku_list = []
    text_corpus = []

    print("Formulating text corpus mapped to SKUs...")
    for sku, product in products.items():
        # Text string that strongly represents the product's keywords
        text = f"{product.get('name', '')} {product.get('type', '')} {product.get('category', '')}"
        
        sku_list.append(sku)
        text_corpus.append(text)

    print("Embedding corpus into dense vectors... this might take a few moments.")
    embeddings = model.encode(text_corpus, show_progress_bar=True, convert_to_numpy=True)
    
    # Normalize for cosine similarity mapping nicely into InnerProduct index
    faiss.normalize_L2(embeddings)
    
    dim = embeddings.shape[1]
    # Use Inner Product (Cosine Similarity since normalized)
    index = faiss.IndexFlatIP(dim)
    index.add(embeddings)
    
    # Save the ID mapping
    output_map_path = os.path.join(BASE_DIR, "data/nlp_id_map.pkl")
    with open(output_map_path, "wb") as f:
        pickle.dump(sku_list, f)
        
    output_index_path = os.path.join(BASE_DIR, "data/nlp_faiss.index")
    faiss.write_index(index, output_index_path)

    print(f"✅ Training Complete! Embedded {len(sku_list)} products into NLP Faiss vectors.")
    print(f"Saved to {output_index_path}")

if __name__ == "__main__":
    main()

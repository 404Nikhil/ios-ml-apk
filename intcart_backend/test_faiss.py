import os
import faiss
import pickle
from sentence_transformers import SentenceTransformer
import numpy as np

BASE_DIR = os.path.dirname(os.path.abspath(__file__))

nlp_model = SentenceTransformer("all-MiniLM-L6-v2")
nlp_index = faiss.read_index(os.path.join(BASE_DIR, "data/nlp_faiss.index"))
with open(os.path.join(BASE_DIR, "data/nlp_id_map.pkl"), "rb") as f:
    nlp_id_map = pickle.load(f)

def test_query(q):
    vec = nlp_model.encode([q], convert_to_numpy=True)
    faiss.normalize_L2(vec)
    D, I = nlp_index.search(vec, 3)
    print(f"\nQuery: '{q}'")
    for i in range(3):
        print(f"  Match: {nlp_id_map[I[0][i]]} | Cosine: {D[0][i]:.3f}")

test_query("I want a frying pan")
test_query("pc")
test_query("computer")
test_query("cookware set")
test_query("living room furniture")

import json
import numpy as np
import faiss
import pickle
from gensim.models import Word2Vec

# -------------------------------
# LOAD DATA
# -------------------------------
with open("data/transactions.json") as f:
    transactions = json.load(f)

print("Loaded transactions:", len(transactions))


# -------------------------------
# TRAIN ITEM2VEC
# -------------------------------
model = Word2Vec(
    sentences=transactions,
    vector_size=64,
    window=5,
    min_count=1,
    workers=4,
    epochs=10
)

model.save("data/item2vec.model")
print("✅ Model trained")


# -------------------------------
# BUILD EMBEDDINGS MATRIX
# -------------------------------
ids = list(model.wv.index_to_key)
vectors = np.array([model.wv[i] for i in ids]).astype("float32")

# normalize
faiss.normalize_L2(vectors)

# -------------------------------
# BUILD FAISS INDEX
# -------------------------------
index = faiss.IndexFlatIP(vectors.shape[1])
index.add(vectors)

faiss.write_index(index, "data/faiss.index")

# save id mapping
with open("data/id_map.pkl", "wb") as f:
    pickle.dump(ids, f)

print("✅ FAISS index built:", len(ids))
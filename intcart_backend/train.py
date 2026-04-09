from gensim.models import Word2Vec
import pickle, numpy as np

with open("data/transactions.pkl", "rb") as f:
    transactions = pickle.load(f)

model = Word2Vec(transactions, vector_size=64, window=5, min_count=1, workers=4, epochs=10)

model.save("data/item2vec.model")

vectors, id_map = [], []

for word in model.wv.index_to_key:
    vectors.append(model.wv[word])
    id_map.append(word)

vectors = np.array(vectors)

np.save("data/embeddings.npy", vectors)

with open("data/id_map.pkl", "wb") as f:
    pickle.dump(id_map, f)
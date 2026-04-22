import pickle
import json
import os

with open("/Users/hilkin/Development/AI-THON/intcart_backend/data/image_embeddings.pkl", "rb") as f:
    orig = pickle.load(f)
    
with open("/Users/hilkin/Development/AI-THON/intcart_backend/data/products.json") as f:
    products = json.load(f)

new_embs = {}
for pid, val in products.items():
    if 'image' in val:
        filename = os.path.basename(val['image'])
        key = os.path.splitext(filename)[0]
        if pid in orig:
            new_embs[pid] = orig[pid]
        elif key in orig:
            new_embs[pid] = orig[key]

with open("/Users/hilkin/Development/AI-THON/intcart_backend/data/image_embeddings.pkl", "wb") as f:
    pickle.dump(new_embs, f)
print("✅ Updated image embeddings mapped to SKUs!")

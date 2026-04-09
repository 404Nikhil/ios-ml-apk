import clip
import torch
from PIL import Image
import os
import pickle
import numpy as np

device = "cpu"
model, preprocess = clip.load("ViT-B/32", device=device)

image_folder = "images"
image_embeddings = {}

for file in os.listdir(image_folder):
    if file.endswith(".jpg") or file.endswith(".png"):

        product_id = os.path.splitext(file)[0]

        try:
            image_path = os.path.join(image_folder, file)

            image = preprocess(Image.open(image_path)).unsqueeze(0).to(device)

            with torch.no_grad():
                emb = model.encode_image(image)

            emb = emb.cpu().numpy()[0]
            emb = emb / np.linalg.norm(emb)

            image_embeddings[product_id] = emb

            print("Processed:", product_id)

        except Exception as e:
            print("Error:", file, e)

# save
with open("data/image_embeddings.pkl", "wb") as f:
    pickle.dump(image_embeddings, f)

print("✅ Image embeddings generated:", len(image_embeddings))
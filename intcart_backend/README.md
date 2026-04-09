# IntCart — Intelligent Cart Recommendation Engine

An AI-powered product recommendation API that uses **Item2Vec**, **FAISS**, and **CLIP image embeddings** to suggest contextually relevant products based on a user's shopping cart.

---

## Project Structure

```
intcart/
├── app.py                 # FastAPI server — recommendation engine + /skus endpoint
├── generate_data.py       # Step 1: Generate synthetic products & transactions
├── fix_products.py        # Step 2: Add human-readable names to products
├── train.py               # Step 3 (alt): Train Item2Vec & save embeddings
├── build_index.py         # Step 3: Train Item2Vec + build FAISS index
├── image_embed.py         # Step 4: Generate CLIP image embeddings
├── images/                # Product images (pan, pot, knife, sofa, chair, etc.)
├── data/                  # Generated model artefacts
│   ├── products.json
│   ├── transactions.json
│   ├── transactions.pkl
│   ├── item2vec.model
│   ├── embeddings.npy
│   ├── faiss.index
│   ├── id_map.pkl
│   └── image_embeddings.pkl
└── mock-api/
    └── responses/
        └── skus.json      # Product catalogue with real image paths
```

---

## Prerequisites

- **Python 3.9+**
- **pip** (or pip3)

---

## Setup

### 1. Clone the repository

```bash
git clone https://github.com/404Nikhil/intcart.git
cd intcart
```

### 2. Install dependencies

```bash
pip install fastapi uvicorn numpy faiss-cpu gensim
```

For image embeddings (optional — only needed if regenerating):

```bash
pip install torch clip-by-openai Pillow
```

---

## Rebuilding the Model (Optional)

The `data/` folder already contains pre-built model files. If you want to regenerate everything from scratch:

```bash
# Step 1 — Generate synthetic products & transactions
python generate_data.py

# Step 2 — Add readable names to products
python fix_products.py

# Step 3 — Train Item2Vec model + build FAISS index
python build_index.py

# Step 4 — Generate CLIP image embeddings from product images
python image_embed.py
```

> **Note:** `train.py` is an alternative to `build_index.py` that saves embeddings as `.npy` instead of building a FAISS index directly.

---

## Running the Server

```bash
uvicorn app:app --host 0.0.0.0 --port 8000 --reload
```

The API will be available at **http://localhost:8000**

---

## API Endpoints

### `POST /recommend`

Get product recommendations based on cart contents.

**Request:**

```bash
curl -X POST http://localhost:8000/recommend \
  -H "Content-Type: application/json" \
  -d '["pan_0", "knife_30"]'
```

**Response:**

```json
{
  "sections": [
    {
      "title": "Frequently bought together",
      "items": [
        {
          "id": "spatula_21",
          "name": "spatula",
          "type": "spatula",
          "category": "cookware",
          "price": 639,
          "image": "/images/spatula_2.jpg"
        }
      ]
    },
    {
      "title": "Complete your cooking setup",
      "items": [...]
    },
    {
      "title": "Similar items",
      "items": [...]
    }
  ]
}
```

The recommendation engine returns three sections:

| Section | Logic |
|---|---|
| **Frequently bought together** | Rule-based bundles (e.g., pan → spatula, pot, knife) |
| **Complete your setup** | FAISS nearest-neighbour search + image similarity scoring |
| **Similar items** | Best-priced items of the same product types in the cart |

---

### `GET /skus`

Returns the full product catalogue with real product images.

```bash
curl http://localhost:8000/skus
```

---

### `GET /images/{filename}`

Serves static product images.

```bash
# Example
http://localhost:8000/images/pan_1.jpg
```

---

## How It Works

```
Cart Items
    │
    ▼
┌────────────────────┐
│  Item2Vec Embeddings │ ──► Mean vector of cart items
└────────────────────┘
    │
    ▼
┌────────────────────┐
│   FAISS Index       │ ──► Top-30 nearest neighbours
└────────────────────┘
    │
    ▼
┌────────────────────┐
│  Scoring & Ranking  │
│  • Cosine similarity│
│  • Category filter   │
│  • Image similarity  │ ──► CLIP embeddings boost (+0.3)
│  • Category boost    │ ──► Same category boost (+0.5)
└────────────────────┘
    │
    ▼
┌────────────────────┐
│  Bundle Rules       │ ──► pan→spatula, knife→cutting_board, etc.
└────────────────────┘
    │
    ▼
  Final Response (3 sections)
```

---

## Product Categories

| Category | Product Types |
|---|---|
| **Cookware** | pan, pot, spatula, knife, cutting_board |
| **Furniture** | sofa, chair, coffee_table |
| **Dining** | table, plate, glass |

---

## License

MIT

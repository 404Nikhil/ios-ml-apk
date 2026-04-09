import json
import random

# -------------------------------
# PRODUCT TYPES PER CATEGORY
# -------------------------------
catalog = {
    "cookware": ["pan", "pot", "spatula", "knife", "cutting_board"],
    "furniture": ["sofa", "chair", "coffee_table"],
    "dining": ["table", "plate", "glass"]
}

products = {}
product_id = 0

# -------------------------------
# GENERATE PRODUCTS
# -------------------------------
for category, types in catalog.items():
    for t in types:
        for i in range(10): 
            pid = f"{t}_{product_id}"
            products[pid] = {
                "type": t,
                "category": category,
                "price": random.randint(500, 5000),
                "name": t
            }
            product_id += 1

# -------------------------------
# SAVE PRODUCTS
# -------------------------------
with open("data/products.json", "w") as f:
    json.dump(products, f, indent=2)

print("✅ Products generated:", len(products))


# -------------------------------
# GENERATE TRANSACTIONS
# -------------------------------
transactions = []

for _ in range(15000):

    category = random.choice(list(catalog.keys()))
    types = catalog[category]

    # pick 2–4 types from same category
    chosen_types = random.sample(types, k=random.randint(2, min(4, len(types))))

    cart = []

    for t in chosen_types:
        candidates = [pid for pid, v in products.items() if v["type"] == t]
        cart.append(random.choice(candidates))

    transactions.append(cart)

# -------------------------------
# SAVE TRANSACTIONS
# -------------------------------
with open("data/transactions.json", "w") as f:
    json.dump(transactions, f)

print("✅ Transactions generated:", len(transactions))
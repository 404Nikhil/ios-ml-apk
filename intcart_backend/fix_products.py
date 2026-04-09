import json

with open("data/products.json") as f:
    products = json.load(f)

for pid, data in products.items():
    # convert type to readable name
    name = data["type"].replace("_", " ")
    data["name"] = name

with open("data/products.json", "w") as f:
    json.dump(products, f, indent=2)

print("✅ Added name field to all products")
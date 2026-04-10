import json
import random
import os

with open('/Users/hilkin/Development/AI-THON/intcart_backend/mock-api/responses/skus.json', 'r') as f:
    skus_data = json.load(f)

def map_type(ptype):
    mapping = {
        'fry-pans': 'pan',
        'fry-pans-skillets': 'pan',
        'saucepans': 'pot',
        'dutch-ovens': 'pot',
        'stockpots': 'pot',
        'braisers': 'pot',
        'spatulas': 'spatula',
        'knife-sets': 'knife',
        'chefs-knives': 'knife',
        'santoku-knives': 'knife',
        'bread-knives': 'knife',
        'paring-knives': 'knife',
        'cutting-boards': 'cutting_board',
        'dining-tables': 'table',
        'accent-chairs': 'chair',
        'dining-chairs': 'chair',
        'dinner-plates': 'plate',
        'salad-plates': 'plate',
        'charger-plates': 'plate',
        'sofas': 'sofa',
        'coffee-tables': 'coffee_table',
        'wine-glasses': 'glass',
        'martini-glasses': 'glass',
        'rocks-glasses': 'glass',
        'glassware': 'glass',
    }
    return mapping.get(ptype, 'other')

def map_category(t):
    if t in ['pan', 'pot', 'spatula', 'knife', 'cutting_board']:
        return 'cookware'
    if t in ['sofa', 'chair', 'coffee_table']:
        return 'furniture'
    if t in ['table', 'plate', 'glass']:
        return 'dining'
    return 'other'

products = {}

for sku in skus_data:
    pid = sku['id']
    ptype = sku.get('properties', {}).get('productType', '')
    t = map_type(ptype)
    cat = map_category(t)
    price = sku.get('price', {}).get('sellingPrice', 0)
    name = sku.get('name', 'Unknown')
    
    img = '/images/default.jpg'
    if 'media' in sku and 'images' in sku['media'] and len(sku['media']['images']) > 0:
        img = sku['media']['images'][0]['path']
        
    products[pid] = {
        "type": t,
        "category": cat,
        "price": price,
        "name": name,
        "image": img # we store image directly
    }

with open("/Users/hilkin/Development/AI-THON/intcart_backend/data/products.json", "w") as f:
    json.dump(products, f, indent=2)

print("✅ Products generated:", len(products))

# Group by category
catalog = {}
for pid, val in products.items():
    cat = val['category']
    if cat not in catalog:
        catalog[cat] = []
    catalog[cat].append(pid)

transactions = []
import pickle

for _ in range(15000):
    cat = random.choice(list(catalog.keys()))
    if cat == 'other': continue
    
    available_items = catalog[cat]
    # to make it realistic, we pick items of different types
    types_in_cat = list(set([products[pid]['type'] for pid in available_items]))
    
    chosen_types = random.sample(types_in_cat, k=random.randint(2, min(4, len(types_in_cat))))
    cart = []
    
    for t in chosen_types:
        candidates = [pid for pid in available_items if products[pid]["type"] == t]
        cart.append(random.choice(candidates))
        
    transactions.append(cart)

with open("/Users/hilkin/Development/AI-THON/intcart_backend/data/transactions.json", "w") as f:
    json.dump(transactions, f)

with open("/Users/hilkin/Development/AI-THON/intcart_backend/data/transactions.pkl", "wb") as f:
    pickle.dump(transactions, f)

print("✅ Transactions generated:", len(transactions))

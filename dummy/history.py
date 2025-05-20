import firebase_admin
from firebase_admin import credentials, firestore
from datetime import datetime, timedelta
import random

cred = credentials.Certificate("serviceAccountKey.json")  
firebase_admin.initialize_app(cred)

db = firestore.client()

uid = "xCzmnw5RgnUXwkefe0SfNlIjL9T2"
collection_path = f"users/{uid}/mealHistory"

sample_meals = ["ChickenSalad", "TofuBowl", "Pasta", "BeefBowl", "Sushi"]
sample_restaurant_ids = ["r1", "r2", "r3", "r4", "r5"]

for i in range(5):
    now = datetime.utcnow() - timedelta(days=i)
    timestamp = now.isoformat() + "Z"
    meal_name = random.choice(sample_meals)
    restaurant_id = random.choice(sample_restaurant_ids)
    
    meal_id = f"{timestamp}_{meal_name.replace(' ', '')}"
    stub_meal_input = {
        "profile": {
            "time": timestamp,
            "mealId": meal_id,
            "name": meal_name,
            "restaurantId": restaurant_id
        }
    }
    db.collection(collection_path).document(meal_id).set(stub_meal_input)
print("Stub meal history added to Firestore.")
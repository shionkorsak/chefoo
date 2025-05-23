import firebase_admin
from firebase_admin import credentials, firestore
from datetime import datetime, timedelta
import random

# Initialize Firebase
cred = credentials.Certificate("serviceAccountKey.json")  
firebase_admin.initialize_app(cred)

db = firestore.client()

uid = "xCzmnw5RgnUXwkefe0SfNlIjL9T2"
collection_path = f"users/{uid}/mealHistory"

# Sample restaurants
restaurants = [
    {"id": "resto_vegan_corner", "name": "Vegan Corner", "tags": ["vegan", "organic"]},
    {"id": "resto_spicy_heaven", "name": "Spicy Heaven", "tags": ["spicy", "thai"]},
    {"id": "resto_garden_bites", "name": "Garden Bites", "tags": ["salad", "gluten-free"]},
    {"id": "resto_tofu_house", "name": "Tofu House", "tags": ["tofu", "asian fusion"]},
    {"id": "resto_herb_delight", "name": "Herb Delight", "tags": ["herbal", "healthy"]},
]

# Sample meals
meals = [
    {"name": "Green Curry", "ingredients": ["tofu", "basil", "green chili"]},
    {"name": "Spicy Noodle Bowl", "ingredients": ["rice noodles", "chili oil", "bok choy"]},
    {"name": "Tofu Power Bowl", "ingredients": ["tofu", "quinoa", "avocado"]},
    {"name": "Garden Salad Wrap", "ingredients": ["lettuce", "tomato", "carrot", "hummus"]},
    {"name": "Mushroom Stir Fry", "ingredients": ["mushroom", "soy sauce", "ginger"]},
    {"name": "Pumpkin Soup", "ingredients": ["pumpkin", "coconut cream", "nutmeg"]},
    {"name": "Herb Rice Bowl", "ingredients": ["brown rice", "basil", "mint", "olive oil"]},
    {"name": "Vegan Pancakes", "ingredients": ["oats", "banana", "soy milk"]},
    {"name": "Sweet Potato Toast", "ingredients": ["sweet potato", "peanut butter", "chia seeds"]},
    {"name": "Avocado Sushi", "ingredients": ["avocado", "seaweed", "rice"]},
]

# Helper: generate ISO timestamp for a given date and meal time
def iso_timestamp(base_date: datetime, hour: int) -> str:
    ts = base_date.replace(hour=hour, minute=0, second=0, microsecond=0)
    return ts.isoformat(timespec='milliseconds') + 'Z'

# Generate 3 meals per day for 14 days (-7 to +6)
today = datetime.utcnow()
total_days = 14
meals_per_day = 3
meal_hours = [8, 13, 19]  # Breakfast, Lunch, Dinner

counter = 0

for day_offset in range(-7, 7):
    day = today + timedelta(days=day_offset)

    for meal_index in range(meals_per_day):
        hour = meal_hours[meal_index]

        restaurant = restaurants[(counter + meal_index) % len(restaurants)]
        meal = meals[(counter + meal_index) % len(meals)]

        timestamp = iso_timestamp(day, hour)
        meal_name = f"{meal['name']}_{hour}h"
        meal_id = f"{timestamp}_{meal_name.replace(' ', '')}"

        meal_input = {
            "profile": {
                "time": timestamp,
                "restaurantId": restaurant["id"],
                "mealId": meal_id,
                "name": meal_name
            },
            "analysis": {
                "tags": restaurant["tags"],
                "ingredients": meal["ingredients"],
                "estimatedCalories": random.randint(400, 600),
                "healthyScore": random.randint(70, 95)
            },
            "feedback": {
                "rating": random.randint(3, 5),
                "notes": random.choice([
                    "Delicious and light.", "Too salty for breakfast.", "Perfect for lunch!", 
                    "Refreshing and healthy.", "Loved it!", "Would eat again!"
                ])
            }
        }

        db.document(f"{collection_path}/{meal_id}").set(meal_input)
        print(f"✅ Uploaded: {meal_name} from {restaurant['name']} at {timestamp}")

        counter += 1

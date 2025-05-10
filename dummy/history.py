import firebase_admin
from firebase_admin import credentials, firestore

cred = credentials.Certificate("../serviceAccountKey.json") 
firebase_admin.initialize_app(cred)

db = firestore.client()

user_id = "lNJjg1lo61VsCrpBbyx26w26HU53"

history_entries = [
    {
        "restaurantName": "Spicy Garden",
        "overallRating": 4,
        "notes": "Good spice level, nice ambiance.",
        "meals": [
            {"name": "Green Curry", "rating": 5, "comment": "Perfect spice!"},
            {"name": "Pad Thai", "rating": 3, "comment": "Too sweet for my taste."}
        ],
        "restaurantId": "spicy-garden-id",  # Unique ID for restaurant
        "location": {  # Coordinates of the restaurant
            "lat": 40.730610,
            "lng": -73.935242
        },
        "tags": ["spicy", "thai", "casual"]  # Example tags
    },
    {
        "restaurantName": "Burger Spot",
        "overallRating": 5,
        "notes": "Best burgers in town!",
        "meals": [
            {"name": "Cheeseburger", "rating": 5, "comment": "Juicy and flavorful."},
            {"name": "Fries", "rating": 4, "comment": "Crispy and fresh."}
        ],
        "restaurantId": "burger-spot-id",  # Unique ID for restaurant
        "location": {  # Coordinates of the restaurant
            "lat": 40.712776,
            "lng": -74.005974
        },
        "tags": ["burger", "american", "casual"]  # Example tags
    }
]

for entry in history_entries:
    db.collection(f"users/{user_id}/history").add(entry)

print("Dummy history data added.")

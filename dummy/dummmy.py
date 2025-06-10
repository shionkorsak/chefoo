import firebase_admin
from firebase_admin import credentials, firestore
from datetime import datetime, timedelta
import random

# Initialize Firebase Admin SDK
cred = credentials.Certificate("path/to/serviceAccountKey.json")  # replace with your path
firebase_admin.initialize_app(cred)

db = firestore.client()

# Helper to generate ISO time string
def iso_time(offset_days=0):
    return (datetime.utcnow() - timedelta(days=offset_days)).isoformat() + 'Z'

# Dummy Data
uid = ""
user_doc = {
    "profile": {
        "uid": uid,
        "email": "dummy@example.com",
        "displayName": "Dummy User",
        "photoURL": "https://example.com/photo.jpg",
        "createdAt": firestore.SERVER_TIMESTAMP,
        "calendarIntegration": {
            "enabled": False,
            "lastSyncTime": None,
            "primaryCalendarId": None
        }
    },
    "preferences": {
        "description": ["likes spicy food", "vegetarian"],
        "likedFood": ["tofu", "ramen"],
        "dislikedFood": ["bacon"],
        "cuisine": ["Japanese", "Thai"],
        "dietaryPreferences": ["vegetarian"],
        "allergies": ["peanuts"],
        "lastAnalyzedfromHistory": iso_time(1)
    },
    "healthInsight": {
        "healthScore": 85,
        "lastAnalyzedAt": iso_time(1),
        "weeklyData": [
            {
                "date": iso_time(i).split('T')[0],
                "mealInput": [
                    {
                        "profile": {
                            "time": iso_time(i),
                            "restaurant": {
                                "id": f"res_{i}",
                                "tags": ["vegan", "healthy"],
                                "pictureCategory": "salad"
                            },
                            "mealId": f"{iso_time(i)}_tofu_salad",
                            "name": "Tofu Salad"
                        },
                        "analysis": {
                            "tags": ["light", "vegan"],
                            "ingredients": ["tofu", "lettuce", "tomato"],
                            "estimatedCalories": 350,
                            "healthyScore": random.randint(70, 90)
                        },
                        "feedback": {
                            "rating": 4,
                            "notes": "Tasted great!"
                        }
                    }
                ],
                "ratio": random.uniform(70, 100),
                "comment": "Good nutrition balance."
            } for i in range(7)
        ]
    }
}

db.collection("users").document(uid).set(user_doc)

print("Dummy user data uploaded.")

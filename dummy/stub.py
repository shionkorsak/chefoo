from datetime import datetime, timedelta
import random
import uuid

def generate_iso_timestamp(offset_days=0):
    return (datetime.utcnow() + timedelta(days=offset_days)).isoformat(timespec="milliseconds") + "Z"

def generate_user_profile():
    return {
        "uid": str(uuid.uuid4()),
        "email": "testuser@example.com",
        "displayName": "Test User",
        "photoURL": "https://example.com/avatar.jpg",
        "createdAt": generate_iso_timestamp(-30),
        "calendarIntegration": {
            "enabled": False,
            "lastSyncTime": generate_iso_timestamp(-1),
            "primaryCalendarId": "calendar_123"
        }
    }

def generate_user_preferences():
    return {
        "description": ["loves spicy food", "prefers vegetarian options"],
        "likedFood": ["tofu", "kimchi"],
        "dislikedFood": ["bacon", "cheese"],
        "cuisine": ["Korean", "Thai"],
        "dietaryPreferences": ["vegetarian"],
        "allergies": ["peanuts"],
        "lastAnalyzedfromHistory": generate_iso_timestamp(-3)
    }

def generate_meal_profile(name="Green Curry", restaurant_id="rest_001", offset=0):
    ts = generate_iso_timestamp(offset)
    return {
        "time": ts,
        "restaurantId": restaurant_id,
        "mealId": f"{ts}_{name.replace(' ', '_')}",
        "name": name
    }

def generate_meal_input(name="Green Curry", offset=0):
    return {
        "profile": generate_meal_profile(name, offset=offset),
        "analysis": {
            "tags": ["spicy", "vegan"],
            "ingredients": ["green chili", "tofu", "coconut milk"],
            "estimatedCalories": 450,
            "healthyScore": 88
        },
        "feedback": {
            "rating": 5,
            "notes": "Very flavorful!"
        }
    }

def generate_restaurant_review():
    return {
        "author": "Test User",
        "rating": 4.5,
        "text": "Great ambiance and food!"
    }

def generate_restaurant():
    return {
        "id": "rest_001",
        "name": "Spicy Heaven",
        "overallRating": 4.6,
        "isFavorite": True,
        "tags": ["vegan", "Thai"],
        "notes": "Good for casual dining",
        "review": [generate_restaurant_review()]
    }

def generate_health_insight():
    return {
        "healthScore": 82,
        "weeklyData": [
            {
                "date": generate_iso_timestamp(-i),
                "mealInput": [generate_meal_input(f"Meal {i}", offset=-i)],
                "ratio": round(random.uniform(0.5, 1.0), 2),
                "comment": "Good balance overall."
            } for i in range(7)
        ]
    }

def generate_user_account():
    return {
        "profile": generate_user_profile(),
        "preferences": generate_user_preferences(),
        "healthInsight": generate_health_insight()
    }

# Generate stub
if __name__ == "__main__":
    stub = generate_user_account()
    import json
    print(json.dumps(stub, indent=2))

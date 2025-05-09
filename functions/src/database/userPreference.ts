import * as functions from "firebase-functions/v1";
import { userPreferenceSchema } from "../schema";
import { db } from "../admin";

export const updateUserPreferences = functions.https.onCall(async (data, context) => {
    const uid = context.auth?.uid;
    if (!uid) {
      throw new functions.https.HttpsError("unauthenticated", "User must be authenticated.");
    }
  
    try {
      const validatedData = userPreferenceSchema.parse(data);
      const userRef = db.collection('users').doc(uid);
      await userRef.update({
        "preferences.dietaryPreferences": validatedData.dietaryPreferences,
        "preferences.allergies": validatedData.allergies,
      })
      return { success: true, message: "Preferences updated successfully." };
    } catch (error) {
      console.error("Failed to update preferences:", error);
      if (error instanceof Error && 'issues' in error) {
        throw new functions.https.HttpsError("invalid-argument", "Invalid preference format.");
      }
      throw new functions.https.HttpsError("internal", "Failed to update preferences.");
    }
  });

  
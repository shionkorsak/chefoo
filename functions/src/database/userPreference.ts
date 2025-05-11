import * as functions from "firebase-functions/v1";
import { clientUpdatePreferenceSchema } from "../schema";
import { db } from "../admin";
import { ai } from "../config";

export const updateClientPreferences = functions.https.onCall(async (data, context) => {
    const uid = context.auth?.uid;
    if(!uid) {
        throw new functions.https.HttpsError("unauthenticated", "User must be authenticated.");
    }

    try {
        const validatedData = clientUpdatePreferenceSchema.parse(data);
        const userRef = db.collection('users').doc(uid);

        await userRef.update({
            'preferences.dietaryPreferences': validatedData.dietaryPreferences,
            'preferences.allergies': validatedData.allergies,
        })

        const userSnap = await userRef.get();
        const currentPref = userSnap.exists ? userSnap.data()?.preference || {} : {};

        const prompt = `
        You are a dietary AI assistant. Based on the user's new dietary preferences and allergies, review their existing food profile and remove or modify any items that conflict with the new restrictions.

        Rules:
        - If any item in "likedFood", "dislikedFood", or "description" contradicts the user's dietary preferences (e.g., cheeseburgers for a vegetarian), it must be removed.
        - The response must fully respect the dietary preferences and allergies provided.

        Return a JSON object with the following fields:
        - description: string, rewritten or removed if it contradicts dietary limits.
        - likedFood: array of strings, must NOT include restricted items.
        - dislikedFood: array of strings, cleaned if needed.
        - cuisine: array of strings, optionally revised.

        Existing Preferences:
        ${JSON.stringify(currentPref, null, 2)}

        Dietary Preferences: ${validatedData.dietaryPreferences.join(', ')}
        Allergies: ${validatedData.allergies.join(', ')}

        Respond with a clean and valid JSON object only. Do not include items that conflict with the dietary preferences or allergies.
        `

        const res = await ai.generate({ prompt });

        let parsed;
        try {
            const cleaned = res.text.replace(/^```json\n/, '').replace(/```$/, '').trim();
            parsed = JSON.parse(cleaned);
        } catch (e) {
            console.error("Failed to parse AI response as JSON:", res.text);
            throw new functions.https.HttpsError("internal", "AI response was not valid JSON.");
        }

        await userRef.set({
        preference: {
            description: parsed.description,
            likedFood: parsed.likedFood,
            dislikedFood: parsed.dislikedFood,
            cuisine: parsed.cuisine,
            dietaryPreferences: validatedData.dietaryPreferences,
            allergies: validatedData.allergies,
        }
        }, { merge: true });

        return { success: true, message: "Preferences updated and validated successfully." };

    } catch (error) {
        console.error("Failed to update preferences:", error);
        if (error instanceof Error && 'issues' in error) {
        throw new functions.https.HttpsError("invalid-argument", "Invalid preference format.");
        }
        throw new functions.https.HttpsError("internal", "Failed to update preferences.");
    }
});
import * as functions from "firebase-functions/v1";
import { clientUpdatePreferenceSchema } from "../../schema";
import { db } from "../../admin";
import { ai } from "../../config";
import { z } from 'genkit';

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
        const currentPref = userSnap.exists ? userSnap.data()?.preferences || {} : {};

        const prompt = `
        You are a professional nutritionist and a foodie expert. Review their existing food profile and modify any items that conflict with the new restrictions.

        Rules:
        - If any item in "likedFood", "dislikedFood", or "description" contradicts the user's dietary preferences (e.g., cheeseburgers for a vegetarian), it must be modified.
        - The response must fully respect the dietary preferences and allergies provided.

        Return a JSON object with the following fields:
        - description: array of strings, rewritten if it contradicts dietary limits.
        - likedFood: array of strings, must NOT include restricted items.
        - dislikedFood: array of strings, cleaned if needed.
        - cuisine: array of strings, optionally revised.

        Existing Preferences:
        ${JSON.stringify(currentPref, null, 2)}

        Dietary Preferences: ${validatedData.dietaryPreferences.join(', ')}
        Allergies: ${validatedData.allergies.join(', ')}

        Respond with a clean and valid JSON object only. Do not include items that conflict with the dietary preferences or allergies.
        `

        console.log(currentPref);

        const res = await ai.generate({ prompt });

        let parsed;
        try {
            const cleaned = res.text.replace(/^```json\n/, '').replace(/```$/, '').trim();
            parsed = JSON.parse(cleaned);
        } catch (e) {
            console.error("Failed to parse AI response as JSON:", res.text);
            throw new functions.https.HttpsError("internal", "AI response was not valid JSON.");
        }

        console.log("AI raw response:", res.text);

        await userRef.set({
        preferences: {
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

export const updateUserPreferenceonMealCreateFlow = ai.defineFlow({
  name: 'updateUserPreferenceonMealCreateFlow',
  inputSchema: z.object({
    uid: z.string(),
    mealId: z.string(),
  }),
  outputSchema: z.object({ status: z.string() }),
}, async ({ uid, mealId }) => {
  const mealRef = db.doc(`users/${uid}/mealHistory/${mealId}`);
  const mealSnap = await mealRef.get();

  if (!mealSnap.exists) {
    console.warn(`[Skip] Meal ${mealId} not found for user ${uid}`);
    return { status: 'skipped (meal not found)' };
  }

  const meal = mealSnap.data();
  const mealName = meal?.profile?.name ?? 'Unnamed Meal';
  const notes = meal?.feedback?.notes;

  if (!notes || notes.trim().length < 3) {
    console.warn(`[Skip] No valid notes found for meal ${mealId}`);
    return { status: 'skipped (no notes)' };
  }

  const userRef = db.doc(`users/${uid}`);
  const userDoc = await userRef.get();
  const prefs = userDoc.data()?.preferences ?? {
    likedFood: [],
    dislikedFood: [],
    cuisine: [],
  };

  const prompt = `
The user ate: "${mealName}"
Their comment was: "${notes}"

Here are their current preferences:
Liked Food: ${prefs.likedFood.join(', ') || 'None'}
Disliked Food: ${prefs.dislikedFood.join(', ') || 'None'}
Cuisines: ${prefs.cuisine.join(', ') || 'None'}

Based on the comment, decide:
1. What should be added to liked/disliked food or cuisine.
2. What should be removed because it now seems to contradict the new preference.

Return only this JSON format:
{
  "description": ["..."],
  "likedFood": ["..."],        // final list after additions/removals
  "dislikedFood": ["..."],     // final list after additions/removals
  "cuisine": ["..."]           // final list after additions/removals
}
Only include fields you’re confident about.
`;

  const { text } = await ai.generate({ prompt });

  let updates = {};
  try {
    updates = JSON.parse(text);
  } catch (e) {
    console.warn(`[Parse Fail] Raw AI output:`, text);
    return { status: 'skipped (parse error)' };
  }

  await userRef.set(
    {
      preferences: {
        updates,
      },
    },
    { merge: true }
  );

  return { status: 'success' };
});


export const triggerUpdatePreference = functions.firestore
  .document('users/{uid}/mealHistory/{mealId}')
  .onCreate(async (snap, context) => {
    const { uid, mealId } = context.params;
    const data = snap.data();

    const notes = data?.feedback?.notes ?? '';
    if (!notes) return null;

    console.log(`[Trigger] Updating preferences for ${uid} from meal ${mealId}`);
    await updateUserPreferenceonMealCreateFlow({ uid, mealId });

    return null;
  });
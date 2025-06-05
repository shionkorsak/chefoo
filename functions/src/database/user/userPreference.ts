import * as functions from "firebase-functions/v1";
import { clientUpdatePreferenceSchema } from "../../schema";
import { db } from "../../admin";
import { ai } from "../../config";
import { z } from 'genkit';

function mergeUniqueArrays<T = string>(...arrays: T[][]): T[] {
  return [...new Set(arrays.flat())];
}

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
  const mealName = meal?.profile?.name ?? 'Unnamed meal';
  const notes = meal?.feedback?.notes ?? 'No notes provided.';

  const userRef = db.doc(`users/${uid}`);
  const userDoc = await userRef.get();
  const prefs = userDoc.data()?.preferences ?? {
    likedFood: [],
    dislikedFood: [],
    cuisine: [],
    description: [],
  };

  const prompt = `
You are a helpful assistant.

The user ate: "${mealName}"
Their comment was: "${notes}"

Current preferences:
Liked Food: ${prefs.likedFood.join(', ') || 'None'}
Disliked Food: ${prefs.dislikedFood.join(', ') || 'None'}
Cuisines: ${prefs.cuisine.join(', ') || 'None'}

Update their preferences based on this meal.

Strictly return only this JSON format with no explanation, no markdown, no code block:

{
  "description": ["..."],
  "likedFood": ["..."],
  "dislikedFood": ["..."],
  "cuisine": ["..."]
}

Only include fields you are confident about.
Respond with valid JSON only. Do not wrap in \`\`\` or add any commentary.
`;

  const { text } = await ai.generate({ prompt });

  let updates: Record<string, any> = {};
  try {
    const cleanText = text.trim().replace(/^```json|```$/g, '').trim();
    updates = JSON.parse(cleanText);
  } catch (e) {
    console.warn(`[Parse Fail] Raw AI output:`, text);
    return { status: 'skipped (parse error)' };
  }

  const mergedPrefs: any = { ...prefs };
  for (const key of Object.keys(updates)) {
    if (Array.isArray(updates[key])) {
      mergedPrefs[key] = mergeUniqueArrays(prefs[key] ?? [], updates[key]);
    }
  }

  await userRef.set({ preferences: mergedPrefs }, { merge: true });

  return { status: 'success:', updates };
});


export const triggerUpdatePreference = functions.https.onCall(
  async (data, context) => {
    const uid = context.auth?.uid;
    if (!uid) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'User must be authenticated.'
      );
    }

    const mealId = data.mealId;
    if (!mealId) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Meal ID is required.'
      );
    }

    const mealRef = db.doc(`users/${uid}/mealHistory/${mealId}`);
    const mealSnap = await mealRef.get();

    if (!mealSnap.exists) {
      throw new functions.https.HttpsError(
        'not-found',
        `Meal ${mealId} not found.`
      );
    }

    console.log(`[Callable Trigger] Updating preferences for ${uid} from meal ${mealId}`);

    const result = await updateUserPreferenceonMealCreateFlow({ uid, mealId });

    return { status: result.status };
  }
);
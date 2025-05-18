import * as functions from "firebase-functions/v1";
import { ai } from '../../config';
import { firestore } from 'firebase-admin';
import { mealInputSchema } from '../../schema';
import { z } from 'genkit';

function mergeUniqueArrays<T = string>(...arrays: T[][]): T[] {
  return [...new Set(arrays.flat())];
}

export const processMealBatch = functions.https.onCall(async (data, context) => {
    const uid = context.auth?.uid;
    if(!uid) {
        throw new functions.https.HttpsError("unauthenticated", "User must be authenticated.");
    }

    const db = firestore();
    const userRef = db.collection('users').doc(uid);
    const userDoc = await userRef.get();
    const userData = userDoc.exists ? userDoc.data() : {};
    const currentPref = userData?.preferences || {};
    const lastAnalyzed = currentPref.lastAnalyzedfromHistory || '1970-01-01T00:00:00Z';

    const mealsSnap = await db
        .collection(`users/${uid}/mealsHistory`)
        .where('profile.time', '>', lastAnalyzed)
        .orderBy('profile.time')
        .get();

    const meals = mealsSnap.docs
        .map(doc => mealInputSchema.safeParse(doc.data()))
        .filter(result => result.success)
        .map(result => result.data);

    if(meals.length === 0) {
        console.log('No new meals to analyze.');
        return { message: 'No new meals found' };
    }

    const batchText = meals.map(meal => {
        const { name } = meal.profile;
        const rating = meal.feedback?.rating;
        const notes = meal.feedback?.notes ?? 'No notes';
        const tags = meal.analysis?.tags?.join(', ') ?? 'No tags';
        const ingredients = meal.analysis?.ingredients?.join(', ') ?? 'No ingredients';
        const { estimatedCalories = 0, healthyScore = 0 } = meal.analysis ?? {};
        return `Meal: ${name}
        Rating: ${rating}/5
        Tags: ${tags}
        Ingredients: ${ingredients}
        Estimated Calories: ${estimatedCalories}
        Health Score: ${healthyScore}
        Notes: ${notes}`;
    }).join('\n\n');

    console.log(`batch text: ${batchText}`);

    const prompt = `
        You are a professional nutritionist and a foodie expert. You are tasked to review the food personality of a user.
        Analyze the following meals. Return a JSON with:
        - description: array of strings, user's food personality
        - likedFood: array of strings, meals rated 4-5
        - dislikedFood: array of string, meals rated 1-2
        - cuisine: array of string, based on the likedFood, conclude the type of cuisines they are

        Meals:
        ${batchText}

        JSON:
    `;

    const result = await ai.generate({ prompt });

    console.log(`result of AI: ${result}`);

    let parsed;
    try {
        const cleaned = result.text.replace(/^```json\n/, '').replace(/```$/, '').trim();
        parsed = JSON.parse(cleaned);
    } catch (e) {
        console.error('Failed to parse AI response as JSON:', result.text);
        throw new Error('AI response was not valid JSON');
    }

    const updatedPreferences = {
        description: mergeUniqueArrays(parsed.description ?? [], currentPref.description ?? []),
        likedFood: mergeUniqueArrays(parsed.likedFood ?? [], currentPref.likedFood ?? []),
        dislikedFood: mergeUniqueArrays(parsed.dislikedFood ?? [], currentPref.dislikedFood ?? []),
        cuisine: mergeUniqueArrays(parsed.cuisine ?? [], currentPref.cuisine ?? []),
        dietaryPreferences: currentPref.dietaryPreferences ?? [],
        allergies: currentPref.allergies ?? [],
        lastAnalyzedfromHistory: meals.at(-1)?.profile.time || new Date().toISOString()
    };

    console.log(`updated preferences: ${updatedPreferences}`);

    await userRef.set({ preferences: updatedPreferences }, { merge: true });

    return {
        message: `Updated preferences from ${meals.length} new meals.`,
        preferences: updatedPreferences,
    };
})

// genkit testing
export const processMealBatchFlow = ai.defineFlow(
  {
    name: 'processMealBatchFlow',
    inputSchema: z.object({
      uid: z.string()
    }),
    outputSchema: z.object({
      message: z.string(),
      preferences: z.any()
    })
  },
  async ({ uid }) => {
    const db = firestore();
    const userRef = db.collection('users').doc(uid);
    const userDoc = await userRef.get();
    const userData = userDoc.exists ? userDoc.data() : {};
    const currentPref = userData?.preferences || {};
    const lastAnalyzed = currentPref.lastAnalyzedfromHistory || '1970-01-01T00:00:00Z';

    const mealsSnap = await db
      .collection(`users/${uid}/mealsHistory`)
      .where('profile.time', '>', lastAnalyzed)
      .orderBy('profile.time')
      .get();

    const meals = mealsSnap.docs
      .map(doc => mealInputSchema.safeParse(doc.data()))
      .filter(result => result.success)
      .map(result => result.data);

    if (meals.length === 0) {
      console.log('No new meals to analyze.');
      return { message: 'No new meals found', preferences: currentPref };
    }

    const batchText = meals.map(meal => {
      const { name } = meal.profile;
      const rating = meal.feedback?.rating;
      const notes = meal.feedback?.notes ?? 'No notes';
      const tags = meal.analysis?.tags?.join(', ') ?? 'No tags';
      const ingredients = meal.analysis?.ingredients?.join(', ') ?? 'No ingredients';
      const { estimatedCalories = 0, healthyScore = 0 } = meal.analysis ?? {};
      return `Meal: ${name}
      Rating: ${rating}/5
      Tags: ${tags}
      Ingredients: ${ingredients}
      Estimated Calories: ${estimatedCalories}
      Health Score: ${healthyScore}
      Notes: ${notes}`;
    }).join('\n\n');

    const prompt = `
You are a professional nutritionist and a foodie expert. You are tasked to review the food personality of a user.
Analyze the following meals. Return a JSON with:
- description: array of strings, user's food personality
- likedFood: array of strings, meals rated 4-5
- dislikedFood: array of string, meals rated 1-2
- cuisine: array of string, based on the likedFood, conclude the type of cuisines they are

Meals:
${batchText}

JSON:
`;

    const result = await ai.generate({ prompt });

    let parsed;
    try {
      const cleaned = result.text.replace(/^```json\n/, '').replace(/```$/, '').trim();
      parsed = JSON.parse(cleaned);
    } catch (e) {
      console.error('Failed to parse AI response as JSON:', result.text);
      throw new Error('AI response was not valid JSON');
    }

    const updatedPreferences = {
      description: mergeUniqueArrays(parsed.description ?? [], currentPref.description ?? []),
      likedFood: mergeUniqueArrays(parsed.likedFood ?? [], currentPref.likedFood ?? []),
      dislikedFood: mergeUniqueArrays(parsed.dislikedFood ?? [], currentPref.dislikedFood ?? []),
      cuisine: mergeUniqueArrays(parsed.cuisine ?? [], currentPref.cuisine ?? []),
      dietaryPreferences: currentPref.dietaryPreferences ?? [],
      allergies: currentPref.allergies ?? [],
      lastAnalyzedfromHistory: meals.at(-1)?.profile.time || new Date().toISOString()
    };

    await userRef.set({ preferences: updatedPreferences }, { merge: true });

    return {
      message: `Updated preferences from ${meals.length} new meals.`,
      preferences: updatedPreferences,
    };
  }
);
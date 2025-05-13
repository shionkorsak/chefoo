import { z } from 'genkit';
import { ai } from '../config';
import { firestore } from 'firebase-admin';
import { restaurantSchema } from '../schema';

function mergeUniqueArrays<T = string>(...arrays: T[][]): T[] {
  return [...new Set(arrays.flat())];
}

export const updatePreference = ai.defineFlow({
  name: 'updatePreference',
  inputSchema: z.object({
    userId: z.string()
  })
}, async ({ userId }) => {
  const db = firestore();
  const historySnap = await db.collection(`users/${userId}/history`).get();
  if (historySnap.empty) return;

  const historyData = historySnap.docs.map(doc => doc.data());
  const parsedResults = historyData.map(data => restaurantSchema.safeParse(data));

  const validEntries = parsedResults.filter(r => r.success).map(r => r.data);
  const invalidCount = parsedResults.length - validEntries.length;
  if (invalidCount > 0) {
    console.log(`Skipped ${invalidCount} invalid history entries`);
  }

  const historyText = validEntries.map(entry => {
    const meals = (entry.meals || []).map(
      (m: any) => `- ${m.name}: ${m.rating}/5 - "${m.comment}"`
    ).join('\n');

    return `Restaurant: ${entry.restaurantName}\nMeals:\n${meals}\nOverall: ${entry.overallRating}/5\nNotes: ${entry.notes}`;
  }).join('\n\n');

  const prompt = `
    Based on the following restaurant history, return a JSON object with these fields:
    - description: array of strings, user's food personality
    - likedFood: array of strings, based on the meal input, decide which meal is liked by user
    - dislikedFood: array of strings, based on the meal input, decide which meal is disliked by user
    - cuisine: array of strings, based on the meal input, decide whether the user prefer which country of cuisine they like, this can be left empty

    History:
    ${historyText}

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

  const userRef = db.collection('users').doc(userId);
  const userDoc = await userRef.get();
  const currentPref = userDoc.exists ? userDoc.data()?.preference || {} : {};

  const updatedPreference = {
    description: mergeUniqueArrays([parsed.description], currentPref.description ?? []),
    likedFood: mergeUniqueArrays(parsed.likedFood, currentPref.likedFood ?? []),
    dislikedFood: mergeUniqueArrays(parsed.dislikedFood, currentPref.dislikedFood ?? []),
    cuisine: mergeUniqueArrays(parsed.cuisine, currentPref.cuisine ?? [])
  };

  await userRef.set({ preference: updatedPreference }, { merge: true });
  console.log(`Updated preferences for user: ${userId}`);

  const updatedUserDoc = await userRef.get();
  if (updatedUserDoc.exists && updatedUserDoc.data()?.preference) {
    console.log('Preference successfully updated:', updatedUserDoc.data()?.preference);
  } else {
    console.error('Failed to update or retrieve preferences.');
  }

  return result.text;
});

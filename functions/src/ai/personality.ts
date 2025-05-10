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
},
    async({userId}) => {
        const db = firestore();
        const historySnap = await db.collection(`users/${userId}/history`).get();
        // console.log(historySnap.docs.map(doc => ({ id: doc.id, data: doc.data() })));

        const data = historySnap.docs.map(doc => ({ id: doc.id, data: doc.data() }));
        if(historySnap.empty) return;
        
        const parsedResults = data.map(doc => restaurantSchema.safeParse(doc.data));

        const validEntries = parsedResults
            .filter(res => res.success)
            .map(res => res.data);
        const failedEntries = parsedResults
            .filter(res => !res.success)
        
        if(failedEntries.length > 0) {
            console.log(`Skipped ${failedEntries.length} invalid history entries`);
        }
        const historyText = validEntries.map(entry => {
            const meals = (entry.meals || []).map(
                (m: any) => `- ${m.name}: ${m.rating}/5 - "${m.comment}"`
            ).join('\n');
            return `Restaurant: ${entry.restaurantName}\nMeals:\n${meals}\nOverall: ${entry.overallRating}/5\nNotes: ${entry.notes}`;
        }).join(`\n\n`);

        const prompt = `
            Based on the following restaurant history, return a JSON object with these fields:
            - description: string, user's food personality
            - likedFood: array of strings, based on the meal input, decide which meal is liked by user
            - dislikedFood: array of strings, based on the meal input, decide which meal is disliked by user
            - cuisine: array of strings, based on the meal input, decide whether the user prefer which country of cuisine they like, this can be left empty

            History:
            ${historyText}

            JSON:
        `;

        const result = await ai.generate({
            prompt
        });

        let parsed;
        try {
            const cleanedResponse = result.text.replace(/^```json\n/, '').replace(/```$/, '').trim();
            parsed = JSON.parse(cleanedResponse);
        } catch (e) {
            console.error('Failed to parse AI response as JSON:', result.text);
            throw new Error('AI response was not valid JSON');
        }

        const userRef = db.collection('users').doc(`${userId}`);
        const userDoc = await userRef.get();
        const current = userDoc.exists ? userDoc.data()?.preference || {} : {};

        const updatedPreference = {
            description: mergeUniqueArrays([parsed.description], current.description ?? []),
            likedFood: mergeUniqueArrays(parsed.likedFood, current.likedFood ?? []),
            dislikedFood: mergeUniqueArrays(parsed.dislikedFood, current.dislikedFood ?? []),
            cuisine: mergeUniqueArrays(parsed.cuisine, current.cuisine ?? [])
        };

        await userRef.set({ preference: updatedPreference }, { merge: true});
        console.log(`Updating user at path: users/${userId}`);

        const updatedUserDoc = await userRef.get();
        if (updatedUserDoc.exists) {
            const updatedData = updatedUserDoc.data();
            if (updatedData?.preference) {
                console.log('Preference successfully updated:', updatedData.preference);
            } else {
                console.error('Failed to update preferences.');
            }
        } else {
            console.error('User document not found after update.');
        }
        return result.text;
    }
)
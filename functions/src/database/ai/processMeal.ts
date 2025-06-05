import * as functions from "firebase-functions/v1";
import { ai } from '../../config';
import { firestore } from 'firebase-admin';
import { z } from 'genkit';
import { mealInputSchema, mealAnalysis } from '../../schema'; // adjust to your schema location

export const processMealAnalysis = functions.https.onCall(
  async (data, context) => {
    const { uid, mealId } = data;

    if (!uid || !mealId) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Missing uid or mealId in the request.'
      );
    }

    try {
      const docRef = firestore().doc(`users/${uid}/mealHistory/${mealId}`);
      const docSnap = await docRef.get();

      if (!docSnap.exists) {
        throw new functions.https.HttpsError(
          'not-found',
          `No mealHistory document found for ${uid}/${mealId}.`
        );
      }

      const rawData = docSnap.data();
      const validation = mealInputSchema.safeParse(rawData);

      if (!validation.success) {
        throw new functions.https.HttpsError(
          'invalid-argument',
          `Invalid meal input format: ${validation.error}`
        );
      }

      const name = validation.data.profile.name;
      const notes = validation.data.feedback?.notes ?? 'No notes provided';

      const result = await processMealAnalysisFlow({ name, notes });

      await docRef.update({ analysis: result.analysis });

      return { success: true, message: `Analysis completed for ${uid}/${mealId}` };
    } catch (error: any) {
      console.error(`Error processing meal analysis:`, error);
      throw new functions.https.HttpsError(
        'internal',
        error.message || 'An unexpected error occurred.'
      );
    }
  }
);

export const processMealAnalysisFlow = ai.defineFlow(
    {
        name: 'processMealAnalysisFlow',
        inputSchema: z.object({
            name: z.string(),
            notes: z.string()
        }),
        outputSchema: z.object({
            message: z.string(),
            analysis: mealAnalysis
        })
    },
    async ( input ) => {
        const { name, notes } = input;

        const prompt = `
        You are a full-fledged nutrionist and dietician.
        Given a meal name and notes regarding the meal, return a JSON analysis with:
        - tags: array of keywords for the meal, maximum of 5 keywords
        - ingredients: array of common main ingredients inferred from the name and the notes
        - estimatedCalories: estimated number of calories (integer)
        - healthyScore: a score from 0 to 100 evaluating healthiness of the meal

        Meal Name: ${name}
        Meal Notes: ${notes}

        Respond with only the JSON (do NOT include triple backticks or markdown formatting):
        `

        const result = await ai.generate({ prompt });
        let parsed;
        try {
            const cleaned = result.text.replace(/^```json\n/, '').replace(/```/g, '').trim();
            parsed = JSON.parse(cleaned);
        } catch (e) {
            console.error('Failed to parse AI response:', result.text);
            throw new Error('AI response was not valid JSON');
        }

        const validation = mealAnalysis.safeParse(parsed);
        if (!validation.success) {
        console.error('Validation failed:', validation.error);
        throw new Error('AI result did not match mealAnalysis schema');
        }

        return {
        message: `Analysis completed for meal: ${name}`,
        analysis: validation.data
        };
    }
)
import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import { logger } from 'firebase-functions';
import { ai } from '../../config';
import { firestore } from 'firebase-admin';
import { z } from 'genkit';
import { mealInputSchema, mealAnalysis } from '../../schema'; // adjust to your schema location

export const processMealAnalysis = onDocumentCreated(
  {
    document: 'users/{uid}/mealHistory/{mealId}',
  },
  async (event) => {
    const snap = event.data;
    const { uid, mealId } = event.params;

    if (!snap) {
      logger.warn('No document snapshot found.');
      return;
    }

    const rawData = snap.data();
    const validation = mealInputSchema.safeParse(rawData);

    if (!validation.success) {
      logger.error(`Invalid meal input for ${uid}/${mealId}:`, validation.error);
      return;
    }

    const name = validation.data.profile.name;
    const notes = validation.data.feedback?.notes ?? 'No notes provided';

    try {
      const result = await processMealAnalysisFlow({ name, notes });

      await firestore()
        .doc(`users/${uid}/mealHistory/${mealId}`)
        .update({ analysis: result.analysis });

      logger.info(`Meal analysis saved for ${uid}/${mealId}`);
    } catch (error) {
      logger.error(`Failed to analyze meal for ${uid}/${mealId}:`, error);
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
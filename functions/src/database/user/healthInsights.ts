import * as functions from "firebase-functions/v1";
import { ai } from '../../config';
import { db } from "../../admin";
import { mealInputSchema, healthInsightSchema } from '../../schema';
import { z } from 'genkit';

export const analyzeHealthInsightsFlow = ai.defineFlow(
    {
        name: 'analyzeHealthInsightsFlow',
        inputSchema: z.object({
            uid: z.string(),
        }),
        outputSchema: healthInsightSchema,
    },
    async ({ uid }) => {
        const sevenDaysAgoISO = new Date(Date.now() - 6 * 24 * 60 * 60 * 1000).toISOString();

        const snapshot = await db
            .collection(`users/${uid}/mealHistory`)
            .where('profile.time', '>=', sevenDaysAgoISO)
            .get();
        
        const rawMealsData = snapshot.docs.map(doc => doc.data());
        const parsedMeals = rawMealsData
            .map(meal => mealInputSchema.safeParse(meal))
            .filter(result => result.success)
            .map(result => result.data);

        console.log("parsed meals:", parsedMeals);

        const dailyGroups: Record<string, typeof parsedMeals> = {};
        for(const meal of parsedMeals) {
            const date = new Date(meal.profile.time as string);
            const dayKey = date.toISOString().split('T')[0];

            if (!dailyGroups[dayKey]) dailyGroups[dayKey] = [];
            dailyGroups[dayKey].push(meal);
        }

        const last7Days = [...Array(7)].map((_, i) => {
            const d = new Date();
            d.setDate(d.getDate() -  i);
            return d.toISOString().split('T')[0];
        });
        
        const weeklyData = await Promise.all(
            last7Days.map(async (date) => {
                const meals = dailyGroups[date] ?? [];

                if (meals.length === 0) {
                    return {
                        date,
                        mealInput: [],
                        ratio: 0,
                        comment: 'No meals recorded.',
                    };
                }

                const prompt = `Please analyze the following meals eaten on ${date}. You must return a healthiness ratio (0 to 1) and a one-sentence summary of the meals health that day. Only include the sentence and the ratio. Meals:\n` +
                    meals.map(m => `-${m.profile.name}, tags: ${m.analysis?.tags?.join(', ') ?? 'N/A'}`).join('\n');

                const { text } = await ai.generate({ prompt });

                const ratio = Number(text.match(/ratio.*?([0-9.]+)/i)?.[1]) || 0;
                const comment = text.replace(/.*ratio.*?[0-9.]+/i, '').trim();

                return {
                    date,
                    mealInput: meals,
                    ratio, 
                    comment,
                };
            })
        );

        const healthScore = Math.round(
            (weeklyData.reduce((sum, date) => sum + date.ratio, 0) / 7) * 100
        );

        const lastAnalyzedAt = new Date().toISOString();
        const result = {
            healthScore,
            weeklyData,
            lastAnalyzedAt
        }

        await db.collection('users').doc(uid).set(
            { healthInsight: result },
            { merge: true }
        );
        return result;
    }
)

export const analyzeHealthInsightsDailyFlow = ai.defineFlow(
  {
    name: 'analyzeHealthInsightsDailyFlow',
    inputSchema: z.object({
      uid: z.string(),
      date: z.string(),
    }),
    outputSchema: healthInsightSchema,
  },
  async ({ uid, date }) => {
    const mealsSnapshot = await db
      .collection(`users/${uid}/mealHistory`)
      .where('profile.time', '>=', `${date}T00:00:00.000Z`)
      .where('profile.time', '<', `${date}T23:59:59.999Z`)
      .get();

    const rawMeals = mealsSnapshot.docs.map(doc => doc.data());
    const parsedMeals = rawMeals
      .map(m => mealInputSchema.safeParse(m))
      .filter(r => r.success)
      .map(r => r.data);

    let dailyEntry;
    if (parsedMeals.length === 0) {
      dailyEntry = {
        date,
        mealInput: [],
        ratio: 0,
        comment: 'No meals recorded.',
      };
    } else {
      const prompt = `Please analyze the following meals eaten on ${date}. You must return a healthiness ratio (0 to 1) and a one-sentence summary of the meals health that day. Only include the sentence and the ratio. Meals:\n` +
        parsedMeals.map(m => `-${m.profile.name}, tags: ${m.analysis?.tags?.join(', ') ?? 'N/A'}`).join('\n');

      const { text } = await ai.generate({ prompt });
      const ratio = Number(text.match(/ratio.*?([0-9.]+)/i)?.[1]) * 100 || 0;
      const comment = text.replace(/.*ratio.*?[0-9.]+/i, '').trim();

      dailyEntry = {
        date,
        mealInput: parsedMeals,
        ratio,
        comment,
      };
    }

    const userDoc = await db.collection('users').doc(uid).get();
    const existing = userDoc.data()?.healthInsight;

    const updatedWeekly = [...(existing?.weeklyData ?? [])]
      .filter(d => d.date !== date);

    updatedWeekly.push(dailyEntry);

    updatedWeekly.sort((a, b) => b.date.localeCompare(a.date));
    while (updatedWeekly.length < 7) {
        const missingDate = new Date(updatedWeekly[updatedWeekly.length - 1]?.date ?? new Date());
        missingDate.setDate(missingDate.getDate() - 1);

        const filler = {
            date: missingDate.toISOString().split('T')[0],
            mealInput: [],
            ratio: 0,
            comment: 'No meals recorded.',
        };

        updatedWeekly.push(filler);
    }

    const weeklyData = updatedWeekly
        .sort((a, b) => a.date.localeCompare(b.date))
        .slice(-7);

    const healthScore = Math.round(
      (weeklyData.reduce((sum, d) => sum + d.ratio, 0) / 7) * 100
    );

    const lastAnalyzedAt = new Date().toISOString();
    const result = { healthScore, weeklyData, lastAnalyzedAt };

    await db.collection('users').doc(uid).set({ healthInsight: result }, { merge: true });
    return result;
  }
);

export const updateInsight = functions.firestore
    .document('users/{uid}/mealHistory/{mealId}')
    .onWrite(async (change, context) => {
        const uid = context.params.uid;
        const meal = change.after.exists ? change.after.data() : null;

        if(!meal || !meal.profile?.time) {
            console.warn(`[Skipped] No meal or profile.time found for uid: ${uid}`);
            return null;
        }

        try {
            const time = new Date(meal.profile.time);
            const date = time.toISOString().split('T')[0];

            console.log(`[Trigger] Analyzing health insights for ${uid} on ${date}`);
            await analyzeHealthInsightsDailyFlow({ uid, date });
        } catch (error) {
            console.error(`[Error] Failed to analyze insights:`, error);
        }

        return null;
    })

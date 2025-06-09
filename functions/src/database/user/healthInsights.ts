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

export const updateInsight = functions
  .runWith({ timeoutSeconds: 90 })
  .https.onCall(async (data, context) => {
    const uid = data.uid;
    const mealId = data.mealId;

    if (!uid || !mealId) {
      throw new functions.https.HttpsError('invalid-argument', 'uid and mealId are required.');
    }

    const mealDoc = await db.doc(`users/${uid}/mealHistory/${mealId}`).get();
    if (!mealDoc.exists) {
      throw new functions.https.HttpsError('not-found', `Meal ${mealId} not found.`);
    }

    const meal = mealDoc.data();
    const timeStr = meal?.profile?.time;
    if (!timeStr) {
      throw new functions.https.HttpsError('invalid-argument', 'profile.time is missing.');
    }

    const date = new Date(timeStr).toISOString().split('T')[0];

    const mealSnap = await db.collection(`users/${uid}/mealHistory`)
      .where('profile.time', '>=', `${date}T00:00:00.000Z`)
      .where('profile.time', '<', `${date}T23:59:59.999Z`)
      .get();

    const parsedMeals = mealSnap.docs
      .map(d => mealInputSchema.safeParse(d.data()))
      .filter(p => p.success)
      .map(p => p.data);

    const mealsWithScore = parsedMeals.filter(m => m.analysis?.healthyScore !== undefined);
    const totalHealthyScore = mealsWithScore.reduce((sum, m) => sum + (m.analysis?.healthyScore ?? 0), 0);
    const ratio = mealsWithScore.length > 0
      ? Math.round((totalHealthyScore / mealsWithScore.length))
      : 0;

    let comment = 'No meals recorded.';
    if (parsedMeals.length > 0) {
      const prompt = `Summarize the healthiness of these meals on ${date} in one sentence:\n` +
        parsedMeals.map(m => `- ${m.profile.name}, tags: ${m.analysis?.tags?.join(', ') ?? 'N/A'}`).join('\n');

      try {
        const { text } = await ai.generate({ prompt });
        comment = text.trim();
      } catch (err) {
        console.warn(`[AI] Failed to generate daily comment:`, err);
        comment = 'No summary available.';
      }
    }

    const dailyEntry = {
      date,
      mealInput: parsedMeals,
      ratio,       
      comment,
    };

    const userRef = db.doc(`users/${uid}`);
    const userSnap = await userRef.get();
    const existing = userSnap.data()?.healthInsight;

    const updatedWeekly = [...(existing?.weeklyData ?? [])].filter(d => d.date !== date);
    updatedWeekly.push(dailyEntry);

    // 1. Sort and take latest entries
    const now = new Date();
    const sevenDaysAgo = new Date(now);
    sevenDaysAgo.setDate(now.getDate() - 6); // inclusive of today

    let weeklyData = updatedWeekly
      .filter(d => {
        const entryDate = new Date(d.date);
        return entryDate >= sevenDaysAgo && entryDate <= now;
      })
      .sort((a, b) => a.date.localeCompare(b.date));


    // 2. Pad to exactly 7 entries if needed
    while (weeklyData.length < 7) {
      const lastDate = weeklyData.length > 0
        ? new Date(weeklyData[0].date)
        : new Date();

      lastDate.setDate(lastDate.getDate() - 1);  // go backwards
      const missingDateStr = lastDate.toISOString().split('T')[0];

      weeklyData.unshift({
        date: missingDateStr,
        mealInput: [],
        ratio: 0,
        comment: 'No meals recorded.',
      });
    }

    const healthScore = Math.round(
      (weeklyData.reduce((sum, d) => sum + d.ratio, 0)) / weeklyData.length
    );

    const result = {
      healthScore,
      weeklyData,
      lastAnalyzedAt: new Date().toISOString(),
    };

    const parse = healthInsightSchema.safeParse(result);
    if (!parse.success) {
      console.error('[SchemaError] Invalid healthInsight result:', parse.error);
      throw new functions.https.HttpsError('internal', 'Invalid healthInsight format.');
    }

    await userRef.set({ healthInsight: result }, { merge: true });
    return { status: 'success', result };
  });
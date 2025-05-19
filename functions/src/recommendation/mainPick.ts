import * as functions from "firebase-functions/v1";
import { ai } from '../config';
import { db } from "../admin";
import { z } from 'genkit';
import { userPreferenceSchema } from "../schema";

export const restaurantTagsFlow = ai.defineFlow(
    {
        name: 'restaurantTagsFlow',
        inputSchema: z.string(),
        outputSchema: z.array(z.string())
    },
    async ( input ) => {
        const prompt = `
            You are a food domain expert AI. Given a restaurant name, search the restaurant, generate a few short descriptive tags (such as cuisine, style, vibe, or specialty) that describe the meals that they serve.

            Restaurant Name: ${input}

            ONLY return the tags as a comma-separated list.`;

    const result = await ai.generate({
        prompt,
    });

    const text = result.text.trim();
    const tags = text
        .split(',')
        .map(tag => tag.trim())
        .filter(tag => tag.length > 0);

    return tags;
    }
);

export const mainPickFlow = ai.defineFlow(
    {
        name: 'mainPickFlow',
        inputSchema: z.object({
            uid: z.string(),
            restaurants: z.array(
                z.object({
                    id: z.string(),
                    name: z.string(),
                    rating: z.number(),
                    tags: z.array(z.string()),
                    isFavorite: z.boolean()
                })
            ),
        }),
        outputSchema: z.array(
            z.object({
                id: z.string(),
                tags: z.array(z.string())
            })
        )
    },
    async ({ uid, restaurants }) => {
        const userSnap = await db.collection("users").doc(uid).get();
        if (!userSnap.exists) throw new Error("User not found.");
        const rawPreferences = userSnap.get("preferences");
        const preferences = userPreferenceSchema.parse(rawPreferences || {});

        const preferenceText = `
        User Preferences:
        - Food Personality: ${preferences.description.join('; ') || 'None'}
        - Liked Food: ${preferences.likedFood.join(', ') || 'None'}
        - Disliked Food: ${preferences.dislikedFood.join(', ') || 'None'}
        - Preferred Cuisine: ${preferences.cuisine.join(', ') || 'None'}
        - Dietary Restrictions: ${preferences.dietaryPreferences.join(', ') || 'None'}
        - Allergies: ${preferences.allergies.join(', ') || 'None'}
        `;

        console.log("Flow input length:", restaurants.length);
        const enriched = await Promise.all(
            restaurants.map(async (restaurant) => {
                const res = await restaurantTagsFlow.run(restaurant.name);
                const newTags = res.result;
                console.log(`Generated tags for ${restaurant.name}:`, newTags);
                return { ...restaurant, tags: newTags };
            })
            );


        const restaurantList = enriched.map((r, i) => {
            return `#${i+1}
            ID: ${r.id}
            Name: ${r.name}
            Rating: ${r.rating}
            Tags: ${r.tags.join(', ')}
            Favorite: ${r.isFavorite ? 'Yes' : 'No'}`;
        }).join('\n\n');

        const prompt = `
        You are a smart restaurant recommendation AI.

        You will be given a user's food preferences and a list of restaurants. Your job is to recommend the BEST matching restaurants — you MUST return at least one. If none are perfect, pick the closest matches.

        Return ONLY a valid JavaScript array of restaurant IDs (as strings), like: ["id1", "id2"]

        DO NOT explain. DO NOT return an empty array.
        ${preferenceText}

        Restaurants:
        ${restaurantList}
        
        Recommended restaurant IDs:
        `;

        const response = await ai.generate({prompt});
        console.log(response.text);
        const cleanedText = response.text
            .replace(/```(?:json|javascript)?/gi, '')
            .replace(/```/g, '')
            .trim();
        const recommendedIds = JSON.parse(cleanedText);
        const recommendedRestaurants = enriched.filter(r =>
            recommendedIds.includes(r.id)
        );

        console.log(recommendedRestaurants);
        return recommendedRestaurants.map(r => ({
            id: r.id,
            tags: r.tags
        }));
    }
)

export const mainPick = functions.https.onCall(async (data, context) => {
  try {
    const payload = Array.isArray(data) ? data : data?.data;
    if (!Array.isArray(payload)) {
      throw new functions.https.HttpsError('invalid-argument', `Expected array. Got: ${JSON.stringify(data)}`);
    }

    const uid = context.auth?.uid;
    if (!uid) {
        throw new functions.https.HttpsError("unauthenticated", "User must be authenticated.");
    }

    const result = await mainPickFlow.run({uid: uid, restaurants: payload});
    return result;

  } catch (e: any) {
    throw new functions.https.HttpsError(
      'internal',
      `Failed to generate recommendation: ${e.message || e.toString()}`
    );
  }
});
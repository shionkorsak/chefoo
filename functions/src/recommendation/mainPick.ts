import * as functions from "firebase-functions/v1";
import { ai } from '../config';
import { db } from "../admin";
import { z } from 'genkit';
import { restaurantSchema, userPreferenceSchema } from "../schema";

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

            ONLY return the tags as a comma-separated list. Have the most defining tag as the first one.`;

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

export const restaurantBannerFlow = ai.defineFlow(
    {
        name: 'restaurantBannerFlow',
        inputSchema: z.object({
            name: z.string(),
            tags: z.array(z.string())
        })
    },
    async ({ name, tags }) => {
        const bannerOptions = {
          'american_food': ['Fast Food', 'Diner', 'BBQ Joint', 'Steakhouse', 'Fast Casual Burger Spot'],
          'beefnoodle_food': ['Taiwanese Beef Noodle'],
          'bento_food': ['Bento Box', 'Japanese Lunch Set', 'Teishoku', 'Donburi'],
          'chicken_rice': ['Chicken Rice', 'Hainanese Chicken', 'Singaporean', 'Poached Chicken'],
          'curry': ['Curry', 'Japanese Curry', 'Indian Curry', 'Rice Plate'],
          'dimsum_food': ['Dim Sum', 'Hong Kong', 'Tea House'],
          'duck_rice': ['Roast Duck Rice', 'Cantonese Roast', 'BBQ Duck'],
          'hotpot_food': ['Hot Pot', 'Sichuan Hotpot', 'Shabu-Shabu', 'Mala'],
          'indian_food': ['Indian', 'Tandoori', 'Biryani', 'Naan'],
          'italian_food': ['Pasta', 'Pizza', 'Italian'],
          'korean_food': ['Korean', 'Bibimbap', 'Kimchi', 'Korean Fried Chicken'],
          'mexican_food': ['Mexican', 'Taco', 'Taqueria', 'Burrito'],
          'ramen_food': ['Ramen', 'Tonkotsu', 'Shoyu Ramen', 'Japanese Noodles'],
          'sushi': ['Sushi', 'Sashimi', 'Nigiri', 'Japanese'],
          'thai_food': ['Thai', 'Tomyum', 'Mango', 'Pad Thai'],
          'vietnamese_food': ['Vietnamese', 'Pho', 'Banh Mi', 'Spring Rolls'],
          'vegetarian_food': ['Vegan', 'Vegetarian', 'Plant-Based'],
          'xiaolongbao_food': ['Chinese', 'Xiaolongbao', 'Shanghai', 'Steamed Bun'],
          'yansuji_food': ['Salt & Pepper Chicken', 'Taiwanese Popcorn Chicken', 'Street Food', 'Fried Snacks']
        };

        const categories = Object.keys(bannerOptions);

        console.log(categories.join(', '));

        const prompt = `
    You are a food domain expert. Given a restaurant name and its cuisine tags (which may include abbreviations or colloquial terms), choose the **single most appropriate category key** from this list:

    ${categories.join(', ')}

    Think carefully about what the tags refer to. For example, "K-BBQ" should map to "korean_food".

    Only return the exact category key — nothing else. If nothing matches, return 'default'.

    Restaurant Name: ${name}
    Tags: ${tags.join(', ')}

    Category Key:
    `;

        const result = await ai.generate({ prompt });

        const categoryKey = result.text.trim();

        return {
            pictureCategory: categoryKey
        };
    }
);

export const generateTagsAndBanner = functions.https.onCall(async (data, context) => {
  try {
    const { name } = data;
    if (typeof name !== 'string' || name.trim() === '') {
      throw new functions.https.HttpsError("invalid-argument", "Restaurant name must be a non-empty string.");
    }

    const tagsResult = await restaurantTagsFlow.run(name);
    const tags = tagsResult.result;

    const bannerResult = await restaurantBannerFlow.run({ name, tags });

    return {
      name,
      tags,
      pictureCategory: bannerResult.result.pictureCategory,
    };
  } catch (err: any) {
    console.error("generateTagsAndBanner error:", err);
    throw new functions.https.HttpsError(
      "internal",
      `Failed to generate tags and banner: ${err.message || err.toString()}`
    );
  }
});

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
        outputSchema: restaurantSchema
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

        const restaurantList = restaurants
            .map((r, i) => {
                return `#${i+1}
ID: ${r.id}
Name: ${r.name}
Rating: ${r.rating}
Tags: ${r.tags.join(', ')}
Favorite: ${r.isFavorite ? 'Yes' : 'No'}`;
            })
            .join('\n\n');

        const prompt = `
You are a smart restaurant recommendation AI.

You will be given a user's food preferences and a list of restaurants. Your job is to recommend the SINGLE BEST matching restaurant.

Return ONLY a valid JavaScript array with one restaurant ID (as strings), like: ["id1"]

DO NOT explain. DO NOT return an empty array.
${preferenceText}

Restaurants:
${restaurantList}

Recommended restaurant IDs:
`;

        const response = await ai.generate({prompt});
        console.log(response.text);
        let recommendedId: string;
        let selectedRestaurant: typeof restaurants[0];

        try {
            const cleanedText = response.text
                .replace(/```(?:json|javascript)?/gi, '')
                .replace(/```/g, '')
                .trim();

            const match = cleanedText.match(/\[[^\]]*\]/);
            if (!match) {
                throw new Error(`No array found in AI response: "${cleanedText}"`);
            }

            const recommendedIds = JSON.parse(match[0]);

            if (!Array.isArray(recommendedIds) || recommendedIds.length === 0) {
                throw new Error("Parsed data is not a valid array with at least one ID");
            }

            recommendedId = recommendedIds[0];
            selectedRestaurant = restaurants.find(r => r.id === recommendedId)!;
            if(!selectedRestaurant) throw new Error("Selected restaurant not found.");
        } catch (err) {
            console.error("Failed to parse recommended restaurant IDs:", err);
            console.error("Raw AI output was:", response.text);
            throw new Error("Invalid AI output — could not extract restaurant IDs.");
        }

        const bannerRes = await restaurantBannerFlow.run({
            name: selectedRestaurant.name,
            tags: selectedRestaurant.tags
        });


        const finalResult = {
            id: selectedRestaurant.id,
            tags: selectedRestaurant.tags,
            pictureCategory: bannerRes.result.pictureCategory
        };

        console.log(finalResult);
        return finalResult;
    }
)

export const msgAIFlow = ai.defineFlow(
    {
        name: 'msgAIFlow',
        inputSchema: z.object({
            uid: z.string(),
            message: z.string(),
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
        outputSchema: restaurantSchema,
    },
    async ({ uid, message, restaurants }) => {
        const userSnap = await db.collection("users").doc(uid).get();
        if (!userSnap.exists) throw new Error("User not found.");
        const rawPreferences = userSnap.get("preferences");
        const preferences = userPreferenceSchema.parse(rawPreferences || {});

        const restrictionText = `
User Restriction:
- Dietary Restrictions: ${preferences.dietaryPreferences.join(', ') || 'None'}
- Allergies: ${preferences.allergies.join(', ') || 'None'}
`;

        console.log("Flow input length:", restaurants.length);

        const restaurantList = restaurants.map((r, i) => {
            return `#${i+1}
ID: ${r.id}
Name: ${r.name}
Rating: ${r.rating}
Tags: ${r.tags.join(', ')}
Favorite: ${r.isFavorite ? 'Yes' : 'No'}`;
            })
            .join('\n\n');

        const prompt = `
You are a smart restaurant recommendation AI.

You will be given:
- A user message describing what they want to eat
- Their dietary restrictions and allergies
- A list of available restaurants

Recommend the best restaurant that match the user's message and restrictions. Your job is to recommend the SINGLE BEST matching restaurant.

Return ONLY a valid JavaScript array of restaurant IDs (as strings), like: ["id1"]

DO NOT explain anything. DO NOT return an empty array.

${restrictionText}

User Message:
"${message}"

Restaurants:
${restaurantList}

Recommended restaurant IDs:
        `;

        const response = await ai.generate({ prompt });
        console.log(response.text);
        let recommendedId: string;
        let selectedRestaurant: typeof restaurants[0];

        try {
            const cleanedText = response.text
                .replace(/```(?:json|javascript)?/gi, '')
                .replace(/```/g, '')
                .trim();

            const match = cleanedText.match(/\[[^\]]*\]/);
            if (!match) {
                throw new Error(`No array found in AI response: "${cleanedText}"`);
            }

            const recommendedIds = JSON.parse(match[0]);

            if (!Array.isArray(recommendedIds) || recommendedIds.length === 0) {
                throw new Error("Parsed data is not a valid array with at least one ID.");
            }

            recommendedId = recommendedIds[0];
            selectedRestaurant = restaurants.find(r => r.id === recommendedId)!;
            if (!selectedRestaurant) throw new Error("Selected restaurant not found.");
        } catch (err) {
            console.error("Failed to parse recommended restaurant IDs:", err);
            console.error("Raw AI output was:", response.text);
            throw new Error("Invalid AI output — could not extract restaurant IDs.");
        }

        const bannerRes = await restaurantBannerFlow.run({
            name: selectedRestaurant.name,
            tags: selectedRestaurant.tags
        });

        const finalResult = {
            id: selectedRestaurant.id,
            tags: selectedRestaurant.tags,
            pictureCategory: bannerRes.result.pictureCategory
        }

        console.log(finalResult);
        return finalResult;
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

export const msgAI = functions.https.onCall(async (data, context) => {
  try {
    const uid = context.auth?.uid;
    if (!uid) {
      throw new functions.https.HttpsError("unauthenticated", "User must be authenticated.");
    }

    const { message, restaurants } = data;

    if (typeof message !== "string" || !Array.isArray(restaurants)) {
      throw new functions.https.HttpsError("invalid-argument", "Invalid input format.");
    }

    const result = await msgAIFlow.run({ uid, message, restaurants });
    return result;

  } catch (e: any) {
    console.error("msgAI callable error:", e);
    throw new functions.https.HttpsError(
      "internal",
      `Failed to process message AI flow: ${e.message || e.toString()}`
    );
  }
});
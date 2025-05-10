import { z } from "zod";

// TODO: user's route

export const userProfileSchema = z.object({ // TODO: google calendar link
    uid: z.string(),
    email: z.string().email(),
    displayName: z.string(),
    photoURL: z.string().url().optional(),
    createdAt: z.any()
})

export const userPreferenceSchema = z.object({
    description: z.array(z.string()),
    likedFood: z.array(z.string()),
    dislikedFood: z.array(z.string()),
    cuisine: z.array(z.string()),
    dietaryPreferences: z.array(z.string()),
    allergies: z.array(z.string()),
})

export const healthInsightSchema = z.object({
    healthScore: z.number().min(0).max(100),
    weeklyData: z.array(
        z.object({
            week: z.number(),
            ratio: z.number().min(0).max(1),
            comment: z.string()
        })
    )
})

export const restaurantRatingSchema = z.object({
    rating: z.number().min(1).max(5),
    feedback: z.string().max(1000),
    meal: z.array(z.string()),
    mealImageUrl: z.string().url().optional(),
})

export const restaurantSchema_ = z.object({
    id: z.any(),
    name: z.string(),
    address: z.string(),
    userFeedback: z.string(restaurantRatingSchema).nullable(),
    favorite: z.boolean(),
})

export const mealInput = z.object({
    name: z.string(),
    comment: z.string(),
    rating: z.number(),
})

export const restaurantSchema =  z.object({
    restaurantId: z.string(),
    restaurantName: z.string(),
    location: 
        z.object({
            lat: z.number(),
            lng: z.number(),
        }),
    meals: z.array(
        mealInput
    ),
    overallRating: z.number(),
    tags: z.array(z.string()),
    notes: z.string()
})

export const userAccountSchema = z.object({
    profile: userProfileSchema,
    preferences: userPreferenceSchema,
    healthInsight: healthInsightSchema,
    favoriteRestaurant: z.array(
        restaurantSchema
    )
})

export type UserAccount = z.infer<typeof userAccountSchema>;
export type Preference = z.infer<typeof userPreferenceSchema>;
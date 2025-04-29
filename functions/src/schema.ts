import { z } from "zod";

// TODO: user's route

const userProfileSchema = z.object({ // TODO: google calendar link
    uid: z.string(),
    email: z.string().email(),
    displayName: z.string(),
    photoURL: z.string().url().optional(),
    createdAt: z.any()
})

const userPreferenceSchema = z.object({
    dietaryPreferences: z.array(z.string()),
    allergies: z.array(z.string()),
})

const healthInsightSchema = z.object({
    healthScore: z.number().min(0).max(100),
    weeklyData: z.array(
        z.object({
            week: z.number(),
            ratio: z.number().min(0).max(1)
        })
    )
})

const restaurantRatingSchema = z.object({
    rating: z.number().min(1).max(5),
    feedback: z.string().max(1000),
    mealImageUrl: z.string().url().optional(),
})

const restaurantSchema = z.object({
    id: z.any(),
    favorite: z.boolean(),
})

export const userAccountSchema = z.object({
    profile: userProfileSchema,
    preferences: userPreferenceSchema,
    healthInsight: healthInsightSchema,
    gpsStatus: z.boolean(),
    notificationStatus: z.boolean(),
    restaurantRatings: z.array(
        restaurantRatingSchema
    ),
    restaurantHistory: z.array(
        restaurantSchema
    ),
    favoriteRestaurant: z.array(
        restaurantSchema
    )
})

export type UserAccount = z.infer<typeof userAccountSchema>;
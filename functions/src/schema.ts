import { profile } from "console";
import { z } from "zod";

// TODO: user's route

export const userProfileSchema = z.object({ 
    uid: z.string(),
    email: z.string().email(),
    displayName: z.string(),
    photoURL: z.string().url().optional(),
    createdAt: z.any(),
    calendarIntegration: z.object({
        enabled: z.boolean().default(false),
        lastSyncTime: z.any().optional(),
        primaryCalendarId: z.string().optional()
    }).optional()
})

export const userPreferenceSchema = z.object({
    description: z.array(z.string()).default([]),
    likedFood: z.array(z.string()).default([]),
    dislikedFood: z.array(z.string()).default([]),
    cuisine: z.array(z.string()).default([]),
    dietaryPreferences: z.array(z.string()).default([]),
    allergies: z.array(z.string()).default([]),
})

export const mealProfile = z.object({
    time: z.string(),
    restaurantId: z.string(),
    mealId: z.string(),
    name: z.string(),
})

export const mealAnalysis = z.object({
    tags: z.array(z.string()),
    ingredients: z.array(z.string()),
    estimatedCalories: z.number(),
    healthyScore: z.number(),
})

export const mealInput = z.object({
    profile: mealProfile,
    analysis: mealAnalysis,
    feedback: z.object({
        rating: z.number(),
        notes: z.string().optional(),
    })
})

export const restaurantReview = z.object({
    author: z.string(),
    rating: z.number(),
    text: z.string(),
})

export const restaurantSchema =  z.object({
    id: z.string(),
    name: z.string(),
    overallRating: z.number().min(0).max(5),
    isFavorite: z.boolean().default(false),
    tags: z.array(z.string()),
    notes: z.string().optional(),
    review: z.array(restaurantReview)
})

export const healthInsightSchema = z.object({
    healthScore: z.number().min(0).max(100),
    weeklyData: z.array(
        z.object({
            date: z.string().datetime(),
            mealInput: z.array(mealInput),
            ratio: z.number().min(0).max(1),
            comment: z.string()
        })
    ).length(7)
})

export const userAccountSchema = z.object({
    profile: userProfileSchema,
    preferences: userPreferenceSchema,
    healthInsight: healthInsightSchema
})

export const clientUpdatePreferenceSchema = z.object({
    dietaryPreferences: z.array(z.string()),
    allergies: z.array(z.string())
})

export type UserAccount = z.infer<typeof userAccountSchema>;
export type Preference = z.infer<typeof userPreferenceSchema>;
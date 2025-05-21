"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.clientUpdatePreferenceSchema = exports.userAccountSchema = exports.healthInsightSchema = exports.restaurantSchema = exports.mealInputSchema = exports.mealAnalysis = exports.mealProfile = exports.userPreferenceSchema = exports.userProfileSchema = void 0;
const zod_1 = require("zod");
// TODO: user's route
exports.userProfileSchema = zod_1.z.object({
    uid: zod_1.z.string(),
    email: zod_1.z.string().email(),
    displayName: zod_1.z.string(),
    photoURL: zod_1.z.string().url().optional(),
    createdAt: zod_1.z.any(),
    calendarIntegration: zod_1.z.object({
        enabled: zod_1.z.boolean().default(false),
        lastSyncTime: zod_1.z.any().optional(),
        primaryCalendarId: zod_1.z.string().optional()
    }).optional()
});
exports.userPreferenceSchema = zod_1.z.object({
    description: zod_1.z.array(zod_1.z.string()).default([]),
    likedFood: zod_1.z.array(zod_1.z.string()).default([]),
    dislikedFood: zod_1.z.array(zod_1.z.string()).default([]),
    cuisine: zod_1.z.array(zod_1.z.string()).default([]),
    dietaryPreferences: zod_1.z.array(zod_1.z.string()).default([]),
    allergies: zod_1.z.array(zod_1.z.string()).default([]),
    lastAnalyzedfromHistory: zod_1.z.string().time(),
});
exports.mealProfile = zod_1.z.object({
    time: zod_1.z.string(),
    restaurantId: zod_1.z.string(),
    mealId: zod_1.z.string().regex(/^(\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}.\d{3}Z?)_.+$/, {
        message: "mealId must be formatted as ISO timestamp + underscore + meal name",
    }),
    name: zod_1.z.string(),
});
exports.mealAnalysis = zod_1.z.object({
    tags: zod_1.z.array(zod_1.z.string()),
    ingredients: zod_1.z.array(zod_1.z.string()),
    estimatedCalories: zod_1.z.number(),
    healthyScore: zod_1.z.number(),
});
exports.mealInputSchema = zod_1.z.object({
    profile: exports.mealProfile,
    analysis: exports.mealAnalysis.optional(),
    feedback: zod_1.z.object({
        rating: zod_1.z.number(),
        notes: zod_1.z.string().optional(),
    }).optional()
});
// export const restaurantReview = z.object({
//     author: z.string(),
//     rating: z.number(),
//     text: z.string(),
// })
// export const restaurantSchema =  z.object({
//     id: z.string(),
//     name: z.string(),
//     overallRating: z.number().min(0).max(5),
//     isFavorite: z.boolean().default(false),
//     tags: z.array(z.string()),
//     notes: z.string().optional(),
//     review: z.array(restaurantReview)
// })
exports.restaurantSchema = zod_1.z.object({
    id: zod_1.z.string(),
    tags: zod_1.z.array(zod_1.z.string()),
    pictureCategory: zod_1.z.string(),
});
exports.healthInsightSchema = zod_1.z.object({
    healthScore: zod_1.z.number().min(0).max(100),
    weeklyData: zod_1.z.array(zod_1.z.object({
        date: zod_1.z.string(),
        mealInput: zod_1.z.array(exports.mealInputSchema),
        ratio: zod_1.z.number().min(0).max(1),
        comment: zod_1.z.string()
    })).length(7),
    lastAnalyzedAt: zod_1.z.string()
});
exports.userAccountSchema = zod_1.z.object({
    profile: exports.userProfileSchema,
    preferences: exports.userPreferenceSchema,
    healthInsight: exports.healthInsightSchema
});
exports.clientUpdatePreferenceSchema = zod_1.z.object({
    dietaryPreferences: zod_1.z.array(zod_1.z.string()),
    allergies: zod_1.z.array(zod_1.z.string())
});
//# sourceMappingURL=schema.js.map
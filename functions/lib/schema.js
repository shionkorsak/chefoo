"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.clientUpdatePreferenceSchema = exports.userAccountSchema = exports.restaurantSchema = exports.mealInput = exports.healthInsightSchema = exports.userPreferenceSchema = exports.userProfileSchema = void 0;
const zod_1 = require("zod");
// TODO: user's route
exports.userProfileSchema = zod_1.z.object({
    uid: zod_1.z.string(),
    email: zod_1.z.string().email(),
    displayName: zod_1.z.string(),
    photoURL: zod_1.z.string().url().optional(),
    createdAt: zod_1.z.any()
});
exports.userPreferenceSchema = zod_1.z.object({
    description: zod_1.z.array(zod_1.z.string()),
    likedFood: zod_1.z.array(zod_1.z.string()),
    dislikedFood: zod_1.z.array(zod_1.z.string()),
    cuisine: zod_1.z.array(zod_1.z.string()),
    dietaryPreferences: zod_1.z.array(zod_1.z.string()),
    allergies: zod_1.z.array(zod_1.z.string()),
});
exports.healthInsightSchema = zod_1.z.object({
    healthScore: zod_1.z.number().min(0).max(100),
    weeklyData: zod_1.z.array(zod_1.z.object({
        week: zod_1.z.number(),
        ratio: zod_1.z.number().min(0).max(1),
        comment: zod_1.z.string()
    }))
});
exports.mealInput = zod_1.z.object({
    name: zod_1.z.string(),
    comment: zod_1.z.string(),
    rating: zod_1.z.number(),
});
exports.restaurantSchema = zod_1.z.object({
    restaurantId: zod_1.z.string(),
    restaurantName: zod_1.z.string(),
    location: zod_1.z.object({
        lat: zod_1.z.number(),
        lng: zod_1.z.number(),
    }),
    meals: zod_1.z.array(exports.mealInput),
    overallRating: zod_1.z.number(),
    tags: zod_1.z.array(zod_1.z.string()),
    notes: zod_1.z.string()
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
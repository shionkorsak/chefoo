"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.userAccountSchema = exports.restaurantSchema = exports.restaurantRatingSchema = exports.healthInsightSchema = exports.userPreferenceSchema = exports.userProfileSchema = void 0;
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
    dietaryPreferences: zod_1.z.array(zod_1.z.string()),
    allergies: zod_1.z.array(zod_1.z.string()),
});
exports.healthInsightSchema = zod_1.z.object({
    healthScore: zod_1.z.number().min(0).max(100),
    weeklyData: zod_1.z.array(zod_1.z.object({
        week: zod_1.z.number(),
        ratio: zod_1.z.number().min(0).max(1)
    }))
});
exports.restaurantRatingSchema = zod_1.z.object({
    rating: zod_1.z.number().min(1).max(5),
    feedback: zod_1.z.string().max(1000),
    mealImageUrl: zod_1.z.string().url().optional(),
});
exports.restaurantSchema = zod_1.z.object({
    id: zod_1.z.any(),
    favorite: zod_1.z.boolean(),
});
exports.userAccountSchema = zod_1.z.object({
    profile: exports.userProfileSchema,
    preferences: exports.userPreferenceSchema,
    healthInsight: exports.healthInsightSchema,
    gpsStatus: zod_1.z.boolean(),
    notificationStatus: zod_1.z.boolean(),
    restaurantRatings: zod_1.z.array(exports.restaurantRatingSchema),
    restaurantHistory: zod_1.z.array(exports.restaurantSchema),
    favoriteRestaurant: zod_1.z.array(exports.restaurantSchema)
});
//# sourceMappingURL=schema.js.map
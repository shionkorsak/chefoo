"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || function (mod) {
    if (mod && mod.__esModule) return mod;
    var result = {};
    if (mod != null) for (var k in mod) if (k !== "default" && Object.prototype.hasOwnProperty.call(mod, k)) __createBinding(result, mod, k);
    __setModuleDefault(result, mod);
    return result;
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.updateUserPreferences = void 0;
const functions = __importStar(require("firebase-functions/v1"));
const schema_1 = require("../schema");
const admin_1 = require("../admin");
exports.updateUserPreferences = functions.https.onCall(async (data, context) => {
    const uid = context.auth?.uid;
    if (!uid) {
        throw new functions.https.HttpsError("unauthenticated", "User must be authenticated.");
    }
    try {
        const validatedData = schema_1.userPreferenceSchema.parse(data);
        const userRef = admin_1.db.collection('users').doc(uid);
        await userRef.update({
            "preferences.dietaryPreferences": validatedData.dietaryPreferences,
            "preferences.allergies": validatedData.allergies,
        });
        return { success: true, message: "Preferences updated successfully." };
    }
    catch (error) {
        console.error("Failed to update preferences:", error);
        if (error instanceof Error && 'issues' in error) {
            throw new functions.https.HttpsError("invalid-argument", "Invalid preference format.");
        }
        throw new functions.https.HttpsError("internal", "Failed to update preferences.");
    }
});
//# sourceMappingURL=updatePreference.js.map
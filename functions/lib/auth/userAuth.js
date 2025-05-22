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
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.deleteUserAccount = exports.createUserAccount = void 0;
const functions = __importStar(require("firebase-functions/v1"));
const admin = __importStar(require("firebase-admin"));
const schema_1 = require("../schema");
const admin_1 = require("../admin");
exports.createUserAccount = functions.auth.user().onCreate(async (user) => {
    const { uid, displayName, email, photoURL } = user;
    const userAccount = {
        profile: {
            uid: uid ?? '',
            email: email ?? '',
            displayName: displayName ?? 'Unnamed',
            photoURL: photoURL ?? '',
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        preferences: {
            description: [],
            likedFood: [],
            dislikedFood: [],
            cuisine: [],
            dietaryPreferences: [],
            allergies: [],
            lastAnalyzedfromHistory: new Date().toISOString(),
        },
        healthInsight: {
            healthScore: 0,
            weeklyData: [],
            lastAnalyzedAt: new Date().toISOString(),
        },
    };
    console.log("Creating user for", uid);
    try {
        schema_1.userAccountSchema.parse(userAccount);
        const userRef = admin_1.db.collection('users').doc(uid);
        await userRef.set({
            profile: userAccount.profile,
            preferences: userAccount.preferences,
            healthInsight: userAccount.healthInsight,
        });
        console.log(`Created user doc and subcollections (empty for favorites & history) for UID ${uid}`);
    }
    catch (error) {
        console.error('User creation failed:', error);
    }
});
exports.deleteUserAccount = functions.auth.user().onDelete(async (user) => {
    const userRef = admin_1.db.collection('users').doc(user.uid);
    try {
        await userRef.delete();
        console.log(`User document deleted for UID: ${user.uid}`);
        const subcollections = ['favorite', 'history', 'ratings'];
        await Promise.all(subcollections.map(async (subcollection) => {
            const subcollectionRef = userRef.collection(subcollection);
            const snapshot = await subcollectionRef.get();
            if (!snapshot.empty) {
                const batch = admin.firestore().batch();
                snapshot.docs.forEach((doc) => {
                    batch.delete(doc.ref);
                });
                await batch.commit();
                console.log(`Subcollection "${subcollection}" deleted for UID: ${user.uid}`);
            }
        }));
        console.log(`User account deletion completed for UID: ${user.uid}`);
    }
    catch (error) {
        console.error("Error deleting user document: ", error);
    }
});
//# sourceMappingURL=userAuth.js.map
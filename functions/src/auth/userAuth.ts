import * as functions from "firebase-functions/v1";
import * as admin from "firebase-admin";
import { UserAccount, userAccountSchema } from "../schema";
import { db } from "../admin";

export const createUserAccount =
    functions.auth.user().onCreate(async (user) => {
        const { uid, displayName, email, photoURL } = user;

      const userAccount : UserAccount = {
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
        userAccountSchema.parse(userAccount);
        const userRef = db.collection('users').doc(uid);

        await userRef.set({
            profile: userAccount.profile,
            preferences: userAccount.preferences,
            healthInsight: userAccount.healthInsight,
        });

        console.log(`Created user doc and subcollections (empty for favorites & history) for UID ${uid}`);
      } catch (error) {
        console.error('User creation failed:', error);
      }
    });

export const deleteUserAccount =
    functions.auth.user().onDelete(async (user) => {
      const userRef = db.collection('users').doc(user.uid);

      try {
        await userRef.delete();
        console.log(`User document deleted for UID: ${user.uid}`);

        const subcollections = ['favorite', 'history', 'ratings'];

        await Promise.all(
            subcollections.map(async (subcollection) => {
                const subcollectionRef = userRef.collection(subcollection);
                const snapshot = await subcollectionRef.get();

                if(!snapshot.empty) {
                    const batch = admin.firestore().batch();
                    snapshot.docs.forEach((doc) => {
                        batch.delete(doc.ref);
                    });
                    await batch.commit();
                    console.log(`Subcollection "${subcollection}" deleted for UID: ${user.uid}`);
                }
            })
        );

        console.log(`User account deletion completed for UID: ${user.uid}`);
      } catch (error) {
        console.error("Error deleting user document: ", error);
      }
    });

import * as functions from "firebase-functions/v1";
import * as admin from "firebase-admin";

admin.initializeApp();

export const createUserDocument =
    functions.auth.user().onCreate(async (user) => {
      const userRef = admin.firestore().collection("users").doc(user.uid);

      const userData = {
        uid: user.uid,
        email: user.email ?? null,
        displayName: user.displayName ?? "",
        photoURL: user.photoURL ?? "",
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      };

      try {
        await userRef.set(userData);
        console.log(`User document created for UID: ${user.uid}`);
      } catch (error) {
        console.error("Error creating user document: ", error);
      }
    });

export const deleteUserDocument =
    functions.auth.user().onDelete(async (user) => {
      const userRef = admin.firestore().collection("users").doc(user.uid);

      try {
        await userRef.delete();
        console.log(`User document deleted for UID: ${user.uid}`);
      } catch (error) {
        console.error("Error deleting user document: ", error);
      }
    });

import { onCallGenkit } from "firebase-functions/https";
import { updatePreference } from "./ai/personality";

export { createUserAccount } from "./auth/userAuth";
export { deleteUserAccount } from "./auth/userAuth";
export { updateClientPreferences } from "./database/userPreference";

export const updatePreferenceAI = onCallGenkit(updatePreference);
import { onCallGenkit } from "firebase-functions/https";
import { processMealBatchFlow } from "./database/ai/personality";
import { processMealAnalysisFlow } from "./database/ai/processMeal";

export { createUserAccount } from "./auth/userAuth";
export { deleteUserAccount } from "./auth/userAuth";
export { updateClientPreferences } from "./database/userPreference";

export const updatePreferenceAI = onCallGenkit(processMealBatchFlow);
export const processMealAnalysisAI = onCallGenkit(processMealAnalysisFlow);
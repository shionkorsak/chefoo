import { onCallGenkit } from "firebase-functions/https";
import { processMealBatchFlow } from "./database/ai/personality";
import { processMealAnalysisFlow } from "./database/ai/processMeal";
import { mainPickFlow, restaurantTagsFlow } from "./recommendation/mainPick"
export { createUserAccount } from "./auth/userAuth";
export { deleteUserAccount } from "./auth/userAuth";
export { updateClientPreferences } from "./database/userPreference";
export { mainPick } from "./recommendation/mainPick"

export const updatePreferenceAI = onCallGenkit(processMealBatchFlow);
export const processMealAnalysisAI = onCallGenkit(processMealAnalysisFlow);
export const mainPickAI = onCallGenkit(mainPickFlow);
export const restaurantTagsAI = onCallGenkit(restaurantTagsFlow);

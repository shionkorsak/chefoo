import { onCallGenkit } from "firebase-functions/https";
import { processMealBatchFlow } from "./database/ai/personality";
import { processMealAnalysisFlow } from "./database/ai/processMeal";
import { mainPickFlow, restaurantTagsFlow, restaurantBannerFlow } from "./recommendation/mainPick"
import { analyzeHealthInsightsFlow, analyzeHealthInsightsDailyFlow } from "./database/user/healthInsights";
export { createUserAccount } from "./auth/userAuth";
export { deleteUserAccount } from "./auth/userAuth";
export { updateClientPreferences } from "./database/user/userPreference";
export { mainPick, msgAI, generateTagsAndBanner } from "./recommendation/mainPick"

export const updatePreferenceAI = onCallGenkit(processMealBatchFlow);
export const processMealAnalysisAI = onCallGenkit(processMealAnalysisFlow);
export const mainPickAI = onCallGenkit(mainPickFlow);
export const restaurantTagsAI = onCallGenkit(restaurantTagsFlow);
export const analyzeHealthInsightsAI = onCallGenkit(analyzeHealthInsightsFlow);
export const analyzeHealthInsightsDailyAI = onCallGenkit(analyzeHealthInsightsDailyFlow);
export const restaurantBannerAI = onCallGenkit(restaurantBannerFlow);
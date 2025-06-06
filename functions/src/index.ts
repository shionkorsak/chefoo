import { onCallGenkit } from "firebase-functions/https";
import { processMealAnalysisFlow } from "./database/ai/processMeal";
import { mainPickFlow, restaurantTagsFlow, restaurantBannerFlow, msgAIFlow } from "./recommendation/mainPick"
import { analyzeHealthInsightsFlow, analyzeHealthInsightsDailyFlow } from "./database/user/healthInsights";
import { updateUserPreferenceonMealCreateFlow } from "./database/user/userPreference";

export { createUserAccount } from "./auth/userAuth";
export { deleteUserAccount } from "./auth/userAuth";
export { updateClientPreferences, triggerUpdatePreference } from "./database/user/userPreference";
export { mainPick, msgAI, generateTagsAndBanner } from "./recommendation/mainPick"
export { processMealAnalysis } from "./database/ai/processMeal";
export { processMealBatch } from "./database/ai/personality";
export { updateInsight } from "./database/user/healthInsights";

export const processMealAnalysisAI = onCallGenkit(processMealAnalysisFlow);
export const mainPickAI = onCallGenkit(mainPickFlow);
export const msgAIAI = onCallGenkit(msgAIFlow);
export const restaurantTagsAI = onCallGenkit(restaurantTagsFlow);
export const analyzeHealthInsightsAI = onCallGenkit(analyzeHealthInsightsFlow);
export const analyzeHealthInsightsDailyAI = onCallGenkit(analyzeHealthInsightsDailyFlow);
export const restaurantBannerAI = onCallGenkit(restaurantBannerFlow);
export const updateUserPreferenceonMealCreateAI = onCallGenkit(updateUserPreferenceonMealCreateFlow);
import dotenv from 'dotenv';
import { genkit } from 'genkit';
import { gemini20FlashExp, googleAI } from '@genkit-ai/googleai';

dotenv.config();

export const ai = genkit({
    plugins: [
        googleAI({
            apiKey: process.env.GEMINI_API_KEY,
        })
    ],
    model: gemini20FlashExp.withConfig({
        version: 'gemini-2.0-flash-001'
    })
})
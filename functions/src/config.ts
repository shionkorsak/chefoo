import dotenv from 'dotenv';
import { genkit } from 'genkit';
import { gemini20FlashExp, googleAI } from '@genkit-ai/googleai';

dotenv.config();

const firebaseConfig = {
    apiKey: 'AIzaSyD8KceUgDzBX5K-6KFAWoZ1KtBQWcIUWgU',
    appId: '1:176036392836:android:8f4f7e7d4a9968d46977d1',
    messagingSenderId: '176036392836',
    projectId: 'chefoo-1',
    storageBucket: 'chefoo-1.firebasestorage.app',
}

export const getProjectId = () => firebaseConfig.projectId;

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
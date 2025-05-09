import { z } from 'genkit';
import { ai } from '../config';

export const testGemini = ai.defineFlow({
  name: 'testGemini',
  inputSchema: z.object({
    prompt: z.string(),
  }),
  outputSchema: z.string(),
},
  async ({ prompt }) => {
    const result = await ai.generate({
      prompt: prompt,
    });
    return result.text;
  },
);

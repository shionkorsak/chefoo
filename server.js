import express from 'express';
import cors from 'cors';
import { spawn } from 'child_process';
import dotenv from 'dotenv';

dotenv.config();

const app = express();
app.use(cors());
app.use(express.json());

app.get('/api/populartimes/:placeId', async (req, res) => {
  const { placeId } = req.params;
  console.log(`Getting popular times for place ID: ${placeId}`);
  
  const python = spawn('python3', [
    '-c',
    `
import populartimes
import json
import sys
import ssl
import urllib3

# Disable SSL verification (for development only)
ssl._create_default_https_context = ssl._create_unverified_context
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

try:
    result = populartimes.get_id("${process.env.GOOGLE_MAPS_API_KEY}", "${placeId}")
    if result and 'populartimes' in result:
        print(json.dumps(result))
        print("Success: Found popular times data", file=sys.stderr)
    else:
        print(json.dumps({"error": "No popular times data available"}))
        print("Info: No popular times data available", file=sys.stderr)
except Exception as e:
    error_msg = str(e)
    print(json.dumps({"error": error_msg}))
    print(f"Error: {error_msg}", file=sys.stderr)
`
  ]);

  let data = '';

  python.stdout.on('data', (chunk) => {
    data += chunk;
  });

  python.stderr.on('data', (chunk) => {
    console.log('Python:', chunk.toString().trim());
  });

  python.on('close', (code) => {
    try {
      const result = JSON.parse(data);
      if (result.error) {
        console.log(`No data for ${placeId}:`, result.error);
        res.status(404).json(result);
      } else {
        console.log(`Got data for ${placeId}`);
        res.json(result);
      }
    } catch (e) {
      console.error('Parse error:', e);
      res.status(500).json({ error: 'Failed to parse Python output' });
    }
  });
});

const PORT = process.env.PORT || 3001;
app.listen(PORT, () => {
  console.log(`Backend server running at http:/localhost:${PORT}`);
});
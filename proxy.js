import express from 'express';
import fetch from 'node-fetch';
import cors from 'cors';

const app = express();
const PORT = 3000;

app.use(cors());

const apiKey = 'AIzaSyAUTKMiek6eX3Wx9aHpQpyZ3FSXa5f4nvk'; // ← Replace with your real key

// Proxy for Nearby Search
app.get('/nearbysearch', async (req, res) => {
  const { location, radius, type } = req.query;

  if (!location || !radius || !type) {
    return res.status(400).json({ error: 'Missing required query parameters' });
  }

  const url = `https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=${location}&radius=${radius}&type=${type}&key=${apiKey}`;
  console.log('Forwarding request to Google API (Nearby Search):', url);

  try {
    const googleRes = await fetch(url);
    const data = await googleRes.json();

    if (!googleRes.ok) {
      console.error('Google API error:', data);
      return res.status(googleRes.status).json({ error: data });
    }

    res.json(data);
  } catch (error) {
    console.error('Error fetching from Google API:', error);
    res.status(500).json({ error: 'Failed to fetch from Google API' });
  }
});

// Proxy for Place Details (phone number, etc.)
app.get('/details', async (req, res) => {
  const { place_id } = req.query;

  if (!place_id) {
    return res.status(400).json({ error: 'Missing place_id parameter' });
  }

  const url = `https://maps.googleapis.com/maps/api/place/details/json?place_id=${place_id}&fields=formatted_phone_number,opening_hours,reviews&key=${apiKey}`;
  console.log('Forwarding request to Google API (Place Details):', url);

  try {
    const googleRes = await fetch(url);
    const data = await googleRes.json();

    if (!googleRes.ok) {
      console.error('Google API error:', data);
      return res.status(googleRes.status).json({ error: data });
    }

    res.json(data);
  } catch (error) {
    console.error('Error fetching place details:', error);
    res.status(500).json({ error: 'Failed to fetch place details' });
  }
});

// Start server
app.listen(PORT, () => {
  console.log(`Proxy server running at http://localhost:${PORT}`);
});
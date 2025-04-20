const fs = require('fs');
const path = require('path');
require('dotenv').config();

const indexPath = path.join(__dirname, '../web/index.html');
let html = fs.readFileSync(indexPath, 'utf8');

const fullUrl = `https://maps.googleapis.com/maps/api/js?key=${process.env.GOOGLE_MAPS_API_KEY}&libraries=places&v=weekly`;
html = html.replace(
  /<script src=".*maps\/api\/js.*"><\/script>/,
  `<script src="${fullUrl}"></script>`
);

fs.writeFileSync(indexPath, html);
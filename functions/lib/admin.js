"use strict";
// src/firebase.ts or src/lib/admin.ts
Object.defineProperty(exports, "__esModule", { value: true });
exports.auth = exports.db = exports.app = void 0;
const app_1 = require("firebase-admin/app");
const firestore_1 = require("firebase-admin/firestore");
const auth_1 = require("firebase-admin/auth");
// Initialize admin app only once
const app = (0, app_1.getApps)().length === 0 ? (0, app_1.initializeApp)() : (0, app_1.getApp)();
exports.app = app;
const db = (0, firestore_1.getFirestore)(app);
exports.db = db;
const auth = (0, auth_1.getAuth)(app);
exports.auth = auth;
//# sourceMappingURL=admin.js.map
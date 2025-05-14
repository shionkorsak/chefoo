// src/firebase.ts or src/lib/admin.ts

import { initializeApp, getApp, getApps } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';
import { getAuth } from 'firebase-admin/auth';

// Initialize admin app only once
const app = getApps().length === 0 ? initializeApp() : getApp();

const db = getFirestore(app);
const auth = getAuth(app);

export { app, db, auth };

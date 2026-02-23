// ============================================================================
// Nelna Maintenance System - Firebase Admin SDK Initialisation
// ============================================================================
const admin = require('firebase-admin');
const config = require('./index');
const logger = require('./logger');

let firebaseApp = null;

/**
 * Lazily initialise Firebase Admin SDK.
 * Returns `null` when credentials are missing (dev fallback).
 */
function getFirebaseApp() {
  if (firebaseApp) return firebaseApp;

  const { projectId, privateKey, clientEmail } = config.firebase;

  if (!projectId || !privateKey || !clientEmail) {
    logger.warn(
      'Firebase credentials not configured – push notifications are disabled. ' +
        'Set FIREBASE_PROJECT_ID, FIREBASE_PRIVATE_KEY, and FIREBASE_CLIENT_EMAIL.'
    );
    return null;
  }

  try {
    firebaseApp = admin.initializeApp({
      credential: admin.credential.cert({
        projectId,
        // Private key comes from env var with escaped newlines
        privateKey: privateKey.replace(/\\n/g, '\n'),
        clientEmail,
      }),
    });
    logger.info('Firebase Admin SDK initialised successfully');
    return firebaseApp;
  } catch (error) {
    logger.error('Failed to initialise Firebase Admin SDK:', error);
    return null;
  }
}

/**
 * Return the Firebase Messaging instance, or `null` if not available.
 */
function getMessaging() {
  const app = getFirebaseApp();
  return app ? admin.messaging() : null;
}

module.exports = { getFirebaseApp, getMessaging };

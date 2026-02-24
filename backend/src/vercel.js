// ============================================================================
// Nelna Maintenance System - Vercel Serverless Entry Point
// ============================================================================
// Vercel runs each request as a serverless function invocation.
// We export the Express app directly — @vercel/node handles the rest.
// ============================================================================
const app = require('./app');

module.exports = app;

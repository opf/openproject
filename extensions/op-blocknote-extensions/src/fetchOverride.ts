// This file overrides the "fetch" function and injects the API key as a header
// It is used for local development, but should not be relied upon as a proper
// authentication method with an external OpenProject instance

const originalFetch = window.fetch;
const apiKey = btoa(`apikey:${import.meta.env.VITE_API_KEY}`);
window.fetch = (url, options = {}) => {
  const headers = new Headers(options.headers);
  headers.set('Authorization', `Basic ${apiKey}`);

  return originalFetch(url, { ...options, headers });
};

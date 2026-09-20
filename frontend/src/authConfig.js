export const AUTH_ENABLED = import.meta.env.VITE_AUTH_ENABLED === 'true';

export const msalConfig = {
  auth: {
    clientId: import.meta.env.VITE_AZURE_CLIENT_ID || '',
    authority: `https://login.microsoftonline.com/${import.meta.env.VITE_AZURE_TENANT_ID || 'common'}`,
    redirectUri: window.location.origin,
    postLogoutRedirectUri: window.location.origin,
  },
  cache: {
    cacheLocation: 'sessionStorage',
    storeAuthStateInCookie: false,
  },
};

export const loginRequest = {
  scopes: [`api://${import.meta.env.VITE_AZURE_CLIENT_ID}/access_as_user`],
};

// Mock user para modo dev (VITE_AUTH_ENABLED=false)
export const MOCK_USER = {
  name: import.meta.env.VITE_MOCK_NAME || 'Usuario Dev',
  email: import.meta.env.VITE_MOCK_EMAIL || 'dev@empresa.cl',
  role: import.meta.env.VITE_MOCK_ROLE || 'CLIENTE',
};

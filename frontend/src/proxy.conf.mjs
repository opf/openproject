const PROXY_HOSTNAME = process.env.PROXY_HOSTNAME || process.env.HOST || 'localhost';
const PORT = process.env.PORT || '3000';

export default [
  {
    'context': [
      '/api',
      '/assets/frontend/media'
    ],
    'target': `http://${PROXY_HOSTNAME}:${PORT}`,
    'secure': false,
    'timeout': 360000,
  }
];

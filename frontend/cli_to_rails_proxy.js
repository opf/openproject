const PROXY_HOSTNAME = process.env.PROXY_HOSTNAME || process.env.HOST || 'localhost';
const PORT = process.env.PORT || '3000';

const PROXY_CONFIG = [
  {
    "context": ['/**'],
    "target": `http://${PROXY_HOSTNAME}:${PORT}`,
    "secure": false,
    "timeout": 360000,
    // "bypass": function (req, res, proxyOptions) {
    // }
  }
];

module.exports = PROXY_CONFIG;

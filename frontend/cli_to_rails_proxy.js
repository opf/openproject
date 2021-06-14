const PROXY_HOSTNAME = process.env.PROXY_HOSTNAME || 'localhost';

const PROXY_CONFIG = [
  {
    "context": ['/**'],
    "target": `http://${PROXY_HOSTNAME}:3000`,
    "secure": false,
    "timeout": 360000,
    // "bypass": function (req, res, proxyOptions) {
    // }
  }
];

module.exports = PROXY_CONFIG;

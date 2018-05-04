var PROXY_CONFIG = [
  {
    "context": ['/**'],
    "target": "http://localhost:3000",
    "secure": false
    // "bypass": function (req, res, proxyOptions) {
    // }
  }
];

module.exports = PROXY_CONFIG;

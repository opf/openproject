var PROXY_CONFIG = [
  {
    "context": ['/**'],
    "target": "http://localhost:3000",
    "secure": false,
    "bypass": function (req, res, proxyOptions) {
      // if (req.url === "/main.bundle.js") {
      //   return "/main.bundle.js";
      // }

      // if (req.headers.accept.indexOf("html") !== -1) {
      //     console.log("Skipping proxy for browser request.");
      //     return "/index.html";
      // }
      // req.headers["X-Custom-Header"] = "yes";

      // return false;
    }
  }
];

module.exports = PROXY_CONFIG;

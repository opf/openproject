var PROXY_CONFIG = {
    "/": {
        "target": "http://localhost:3000",
        "secure": false,
        "bypass": function (req, res, proxyOptions) {
            console.log("bypass?");
            console.log("req.url", req.url);

            // if (req.headers.accept.indexOf("html") !== -1) {
            //     console.log("Skipping proxy for browser request.");
            //     return "/index.html";
            // }
            // req.headers["X-Custom-Header"] = "yes";

            // return "/BLA";
            return false;
        }
    }
};

module.exports = PROXY_CONFIG;

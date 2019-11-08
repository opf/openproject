/**
 * @private
 */
const Request = {
    Make: function make(args) {
        return new Promise(function (resolve, reject) {
            var xhr = new XMLHttpRequest();
            xhr.open(args.method || "GET", args.url, true);
            xhr.onload = function (e) {
                console.log(args.url, xhr.readyState, xhr.status)
                if (xhr.readyState === 4) {
                    if (xhr.status === 200) {
                        resolve(xhr.responseXML);
                    } else {
                        reject(xhr.statusText);
                    }
                }
            };
            xhr.send(null);
        });
    }
};

export {Request};

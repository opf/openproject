//var WebSocket = require("ws");

/**
 * @private
 */
export default class BimServerApiWebSocket {
	constructor(baseUrl, bimServerApi) {
		this.connected = false;
		this.openCallbacks = [];
		this.endPointId = null;
		this.listener = null;
		this.tosend = [];
		this.tosendAfterConnect = [];
		this.messagesReceived = 0;
		this.intervalId = null;
		this.baseUrl = baseUrl;
		this.bimServerApi = bimServerApi;
	}

	connect(callback = null) {
		if (this.connected) {
			if (callback != null) {
				callback();
			}
			return Promise.resolve();
		}
		console.info("Connecting websocket");
		var promise = new Promise((resolve, reject) => {
			this.openCallbacks.push(() => {
				resolve();
			});
			if (callback != null) {
				if (typeof callback === "function") {
					this.openCallbacks.push(callback);
				} else {
					console.error("Callback was not a function", callback);
				}
			}
			
			const location = this.bimServerApi.baseUrl.toString().replace('http://', 'ws://').replace('https://', 'wss://') + "/stream";
			
			try {
				this._ws = new WebSocket(location);
				this._ws.binaryType = "arraybuffer";
				this._ws.onopen = this._onopen.bind(this);
				this._ws.onmessage = this._onmessage.bind(this);
				this._ws.onclose = this._onclose.bind(this);
				this._ws.onerror = this._onerror.bind(this);
			} catch (err) {
				console.error(err);
				this.bimServerApi.notifier.setError("WebSocket error" + (err.message !== undefined ? (": " + err.message) : ""));
			}
		});
		return promise;
	}

	_onerror(err) {
		console.log(err);
		this.bimServerApi.notifier.setError("WebSocket error" + (err.message !== undefined ? (": " + err.message) : ""));
	}

	_onopen() {
		this.intervalId = setInterval(() => {
			this.send({"hb": true});
		}, 30 * 1000); // Send hb every 30 seconds
		while (this.tosendAfterConnect.length > 0 && this._ws.readyState == 1) {
			const messageArray = this.tosendAfterConnect.splice(0, 1);
			this._sendWithoutEndPoint(messageArray[0]);
		}
	}

	_sendWithoutEndPoint(message) {
		if (this._ws && this._ws.readyState == 1) {
			this._ws.send(message);
		} else {
			this.tosendAfterConnect.push(message);
		}		
	}
	
	_send(message) {
		if (this._ws && this._ws.readyState == 1 && this.endPointId != null) {
			this._ws.send(message);
		} else {
			console.log("Waiting", message);
			this.tosend.push(message);
		}
	}

	send(object) {
		const str = JSON.stringify(object);
		this.bimServerApi.log("Sending", str);
		this._send(str);
	}

	_onmessage(message) {
		this.messagesReceived++;
		if (this.messagesReceived % 10 === 0) {
//			console.log(this.messagesReceived);
		}
		if (message.data instanceof ArrayBuffer) {
			this.listener(message.data);
		} else {
			const incomingMessage = JSON.parse(message.data);
			if (incomingMessage.id != null) {
				var id = incomingMessage.id;
				if (this.bimServerApi.websocketCalls.has(id)) {
					var fn = this.bimServerApi.websocketCalls.get(id);
					fn(incomingMessage);
					this.bimServerApi.websocketCalls.delete(id);
				}
			} else {
				this.bimServerApi.log("incoming", incomingMessage);
				if (incomingMessage.welcome !== undefined) {
					this._sendWithoutEndPoint(JSON.stringify({"token": this.bimServerApi.token}));
				} else if (incomingMessage.endpointid !== undefined) {
					this.endPointId = incomingMessage.endpointid;
					this.connected = true;
					this.openCallbacks.forEach((callback) => {
						callback();
					});
					while (this.tosend.length > 0 && this._ws.readyState == 1) {
						const messageArray = this.tosend.splice(0, 1);
						console.log(messageArray[0]);
						this._send(messageArray[0]);
					}
					this.openCallbacks = [];
				} else {
					if (incomingMessage.request !== undefined) {
						this.listener(incomingMessage.request);
					} else if (incomingMessage.requests !== undefined) {
						incomingMessage.requests.forEach((request) => {
							this.listener(request);
						});
					}
				}
			}
		}
	}

	_onclose(m) {
		console.log("WebSocket closed", m);
		clearInterval(this.intervalId);
		this._ws = null;
		this.connected = false;
		this.openCallbacks = [];
		this.endpointid = null;
	}
}
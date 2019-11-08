import BimServerApiPromise from './bimserverapipromise.js';
import BimServerApiWebSocket from './bimserverapiwebsocket.js';
import {geometry} from './geometry.js';
import {ifc2x3tc1} from './ifc2x3tc1.js';
import {ifc4} from './ifc4.js';
import Model from './model.js';
import {translations} from './translations_en.js';

//var XMLHttpRequest = require('node-http-xhr');

export { default as BimServerApiPromise } from './bimserverapipromise.js';
export { default as BimServerApiWebSocket } from './bimserverapiwebsocket.js';
export { default as Model } from './model.js';

//import XMLHttpRequest from 'xhr2';

// Where does this come frome? The API crashes on the absence of this
// member function?
String.prototype.firstUpper = function () {
	return this.charAt(0).toUpperCase() + this.slice(1);
};

export default class BimServerClient {
	constructor(baseUrl, notifier = null, translate = null) {
		this.interfaceMapping = {
			"ServiceInterface": "org.bimserver.ServiceInterface",
			"NewServicesInterface": "org.bimserver.NewServicesInterface",
			"AuthInterface": "org.bimserver.AuthInterface",
			"OAuthInterface": "org.bimserver.OAuthInterface",
			"SettingsInterface": "org.bimserver.SettingsInterface",
			"AdminInterface": "org.bimserver.AdminInterface",
			"PluginInterface": "org.bimserver.PluginInterface",
			"MetaInterface": "org.bimserver.MetaInterface",
			"LowLevelInterface": "org.bimserver.LowLevelInterface",
			"NotificationRegistryInterface": "org.bimserver.NotificationRegistryInterface",
		};

		// translate function override
		this.translateOverride = translate;

		// Current BIMserver token
		this.token = null;

		// Base URL of the BIMserver
		this.baseUrl = baseUrl;
		if (this.baseUrl.substring(this.baseUrl.length - 1) == "/") {
			this.baseUrl = this.baseUrl.substring(0, this.baseUrl.length - 1);
		}

		// JSON endpoint on BIMserver
		this.address = this.baseUrl + "/json";

		// Notifier, default implementation does nothing
		this.notifier = notifier;
		if (this.notifier == null) {
			this.notifier = {
				setInfo: function (message) {
					console.log("[default]", message);
				},
				setSuccess: function () {},
				setError: function () {},
				resetStatus: function () {},
				resetStatusQuick: function () {},
				clear: function () {}
			};
		}
		
		// ID -> Resolve method
		this.websocketCalls = new Map(); 

		// The websocket client
		this.webSocket = new BimServerApiWebSocket(baseUrl, this);
		this.webSocket.listener = this.processNotification.bind(this);

		// Cached user object
		this.user = null;

		// Keeps track of the unique ID's required to handle websocket calls that return something
		this.idCounter = 0;
		
		this.listeners = {};

		//    	this.autoLoginTried = false;

		// Cache for serializers, PluginClassName(String) -> Serializer
		this.serializersByPluginClassName = [];

		// Whether debugging is enabled, just a lot more logging
		this.debug = false;

		// Mapping from ChannelId -> Listener (function)
		this.binaryDataListener = {};

		// This mapping keeps track of the prototype objects per class, will be lazily popuplated by the getClass method
		this.classes = {};

		// Schema name (String) -> Schema
		this.schemas = {};
	}

	init(callback) {
		var promise = new Promise((resolve, reject) => {
			this.call("AdminInterface", "getServerInfo", {}, (serverInfo) => {
				this.version = serverInfo.version;
				//const versionString = this.version.major + "." + this.version.minor + "." + this.version.revision;
				
				this.schemas.geometry = geometry.classes;
				this.addSubtypesToSchema(this.schemas.geometry);
				
				this.schemas.ifc2x3tc1 = ifc2x3tc1.classes;
				this.addSubtypesToSchema(this.schemas.ifc2x3tc1);
				
				this.schemas.ifc4 = ifc4.classes;
				this.addSubtypesToSchema(this.schemas.ifc4);

				if (callback != null) {
					callback(this, serverInfo);
				}
				resolve(serverInfo);
			});
		});
		return promise;
	}

	addSubtypesToSchema(classes) {
		for (let typeName in classes) {
			const type = classes[typeName];
			if (type.superclasses != null) {
				type.superclasses.forEach((superClass) => {
					let directSubClasses = classes[superClass].directSubClasses;
					if (directSubClasses == null) {
						directSubClasses = [];
						classes[superClass].directSubClasses = directSubClasses;
					}
					directSubClasses.push(typeName);
				});
			}
		}
	}

	getAllSubTypes(schema, typeName, callback) {
		const type = schema[typeName];
		if (type.directSubClasses != null) {
			type.directSubClasses.forEach((subTypeName) => {
				callback(subTypeName);
				this.getAllSubTypes(schema, subTypeName, callback);
			});
		}
	}

	log(message, message2) {
		if (this.debug) {
			console.log(message, message2);
		}
	}

	translate(key) {
		if (this.translateOverride !== null) {
			return this.translateOverride(key);
		}
		key = key.toUpperCase();
		if (translations != null) {
			const translated = translations[key];
			if (translated == null) {
				console.warn("translation for " + key + " not found, using key");
				return key;
			}
			return translated;
		}
		this.error("no translations");
		return key;
	}

	login(username, password, callback, errorCallback, options) {
		if (options == null) {
			options = {};
		}
		const request = {
			username: username,
			password: password
		};
		this.call("AuthInterface", "login", request, (data) => {
			this.token = data;
			if (options.done !== false) {
				this.notifier.setInfo(this.translate("LOGIN_DONE"), 2000);
			}
			this.resolveUser(callback);
		}, errorCallback, options.busy === false ? false : true, options.done === false ? false : true, options.error === false ? false : true);
	}

	downloadViaWebsocket(msg) {
		msg.action = "download";
		msg.token = this.token;
		this.webSocket.send(msg);
	}

	setBinaryDataListener(topicId, listener) {
		this.binaryDataListener[topicId] = listener;
	}

	clearBinaryDataListener(topicId) {
		delete this.binaryDataListener[topicId];
	}
	
	processNotification(message) {
		if (message instanceof ArrayBuffer) {
			if (message == null || message.byteLength == 0) {
				return;
			}
			const view = new DataView(message, 0, 8);
			const topicId = view.getUint32(0, true) + 0x100000000 * view.getUint32(4, true); // TopicId's are of type long (64 bit)
			const listener = this.binaryDataListener[topicId];
			if (listener != null) {
				listener(message);
			} else {
				console.error("No listener for topicId", topicId);
			}
		} else {
			const intf = message["interface"];
			if (this.listeners[intf] != null) {
				if (this.listeners[intf][message.method] != null) {
					let ar = null;
					this.listeners[intf][message.method].forEach((listener) => {
						if (ar == null) {
							// Only parse the arguments once, or when there are no listeners, not even once
							ar = [];
							let i = 0;
							for (let key in message.parameters) {
								ar[i++] = message.parameters[key];
							}
						}
						listener.apply(null, ar);
					});
				} else {
					console.log("No listeners on interface " + intf + " for method " + message.method);
				}
			} else {
				console.log("No listeners for interface " + intf);
			}
		}
	}

	resolveUser(callback) {
		this.call("AuthInterface", "getLoggedInUser", {}, (data) => {
			this.user = data;
			if (callback != null) {
				callback(this.user);
			}
		});
	}

	logout(callback) {
		this.call("AuthInterface", "logout", {}, () => {
			this.notifier.setInfo(this.translate("LOGOUT_DONE"));
			callback();
		});
	}

	generateRevisionDownloadUrl(settings) {
		return this.baseUrl + "/download?token=" + this.token + (settings.zip ? "&zip=on" : "") + "&topicId=" + settings.topicId;
	}

	generateExtendedDataDownloadUrl(edid) {
		return this.baseUrl + "/download?token=" + this.token + "&action=extendeddata&edid=" + edid;
	}

	getJsonSerializer(callback) {
		this.getSerializerByPluginClassName("org.bimserver.serializers.JsonSerializerPlugin").then((serializer) => {
			callback(serializer);
		});
	}

	getJsonStreamingSerializer(callback) {
		this.getSerializerByPluginClassName("org.bimserver.serializers.JsonStreamingSerializerPlugin").then((serializer) => {
			callback(serializer);
		});
	}

	getSerializerByPluginClassName(pluginClassName) {
		if (this.serializersByPluginClassName[pluginClassName] != null) {
			return this.serializersByPluginClassName[pluginClassName];
		} else {
			var promise = new Promise((resolve, reject) => {
				this.call("PluginInterface", "getSerializerByPluginClassName", {
					pluginClassName: pluginClassName
				}, (serializer) => {
					resolve(serializer);
				});
			});

			this.serializersByPluginClassName[pluginClassName] = promise;
			
			return promise;
		}
	}

	getMessagingSerializerByPluginClassName(pluginClassName, callback) {
		if (this.serializersByPluginClassName[pluginClassName] == null) {
			this.call("PluginInterface", "getMessagingSerializerByPluginClassName", {
				pluginClassName: pluginClassName
			}, (serializer) => {
				this.serializersByPluginClassName[pluginClassName] = serializer;
				callback(serializer);
			});
		} else {
			callback(this.serializersByPluginClassName[pluginClassName]);
		}
	}

	register(interfaceName, methodName, callback, registerCallback) {
		if (callback == null) {
			throw "Cannot register null callback";
		}
		if (this.listeners[interfaceName] == null) {
			this.listeners[interfaceName] = {};
		}
		if (this.listeners[interfaceName][methodName] == null) {
			this.listeners[interfaceName][methodName] = new Set();
		}
		this.listeners[interfaceName][methodName].add(callback);
		if (registerCallback != null) {
			registerCallback();
		}
	}

	registerNewRevisionOnSpecificProjectHandler(poid, handler, callback) {
		this.register("NotificationInterface", "newRevision", handler, () => {
			this.call("NotificationRegistryInterface", "registerNewRevisionOnSpecificProjectHandler", {
				endPointId: this.webSocket.endPointId,
				poid: poid
			}, () => {
				if (callback != null) {
					callback();
				}
			});
		});
	}

	registerNewExtendedDataOnRevisionHandler(roid, handler, callback) {
		this.register("NotificationInterface", "newExtendedData", handler, () => {
			this.call("NotificationRegistryInterface", "registerNewExtendedDataOnRevisionHandler", {
				endPointId: this.webSocket.endPointId,
				roid: roid
			}, () => {
				if (callback != null) {
					callback();
				}
			});
		});
	}

	registerNewUserHandler(handler, callback) {
		this.register("NotificationInterface", "newUser", handler, () => {
			this.call("NotificationRegistryInterface", "registerNewUserHandler", {
				endPointId: this.webSocket.endPointId
			}, () => {
				if (callback != null) {
					callback();
				}
			});
		});
	}

	unregisterNewUserHandler(handler, callback) {
		this.unregister(handler);
		this.call("NotificationRegistryInterface", "unregisterNewUserHandler", {
			endPointId: this.webSocket.endPointId
		}, () => {
			if (callback != null) {
				callback();
			}
		});
	}

	unregisterChangeProgressProjectHandler(poid, newHandler, closedHandler, callback) {
		this.unregister(newHandler);
		this.unregister(closedHandler);
		this.call("NotificationRegistryInterface", "unregisterChangeProgressOnProject", {
			poid: poid,
			endPointId: this.webSocket.endPointId
		}, callback);
	}

	registerChangeProgressProjectHandler(poid, newHandler, closedHandler, callback) {
		this.register("NotificationInterface", "newProgressOnProjectTopic", newHandler, () => {
			this.register("NotificationInterface", "closedProgressOnProjectTopic", closedHandler, () => {
				this.call("NotificationRegistryInterface", "registerChangeProgressOnProject", {
					poid: poid,
					endPointId: this.webSocket.endPointId
				}, () => {
					if (callback != null) {
						callback();
					}
				});
			});
		});
	}

	unregisterChangeProgressServerHandler(newHandler, closedHandler, callback) {
		this.unregister(newHandler);
		this.unregister(closedHandler);
		if (this.webSocket.endPointId != null) {
			this.call("NotificationRegistryInterface", "unregisterChangeProgressOnServer", {
				endPointId: this.webSocket.endPointId
			}, callback);
		}
	}

	registerChangeProgressServerHandler(newHandler, closedHandler, callback) {
		this.register("NotificationInterface", "newProgressOnServerTopic", newHandler, () => {
			this.register("NotificationInterface", "closedProgressOnServerTopic", closedHandler, () => {
				this.call("NotificationRegistryInterface", "registerChangeProgressOnServer", {
					endPointId: this.webSocket.endPointId
				}, () => {
					if (callback != null) {
						callback();
					}
				});
			});
		});
	}

	unregisterChangeProgressRevisionHandler(roid, newHandler, closedHandler, callback) {
		this.unregister(newHandler);
		this.unregister(closedHandler);
		this.call("NotificationRegistryInterface", "unregisterChangeProgressOnProject", {
			roid: roid,
			endPointId: this.webSocket.endPointId
		}, callback);
	}

	registerChangeProgressRevisionHandler(poid, roid, newHandler, closedHandler, callback) {
		this.register("NotificationInterface", "newProgressOnRevisionTopic", newHandler, () => {
			this.register("NotificationInterface", "closedProgressOnRevisionTopic", closedHandler, () => {
				this.call("NotificationRegistryInterface", "registerChangeProgressOnRevision", {
					poid: poid,
					roid: roid,
					endPointId: this.webSocket.endPointId
				}, () => {
					if (callback != null) {
						callback();
					}
				});
			});
		});
	}

	registerNewProjectHandler(handler, callback) {
		this.register("NotificationInterface", "newProject", handler, () => {
			this.call("NotificationRegistryInterface", "registerNewProjectHandler", {
				endPointId: this.webSocket.endPointId
			}, () => {
				if (callback != null) {
					callback();
				}
			});
		});
	}

	unregisterNewProjectHandler(handler, callback) {
		this.unregister(handler);
		if (this.webSocket.endPointId != null) {
			this.call("NotificationRegistryInterface", "unregisterNewProjectHandler", {
				endPointId: this.webSocket.endPointId
			}, () => {
				if (callback != null) {
					callback();
				}
			}, () => {
				// Discard
			});
		}
	}

	unregisterNewRevisionOnSpecificProjectHandler(poid, handler, callback) {
		this.unregister(handler);
		this.call("NotificationRegistryInterface", "unregisterNewRevisionOnSpecificProjectHandler", {
			endPointId: this.webSocket.endPointId,
			poid: poid
		}, () => {
			if (callback != null) {
				callback();
			}
		}, () => {
			// Discard
		});
	}

	unregisterNewExtendedDataOnRevisionHandler(roid, handler, callback) {
		this.unregister(handler);
		this.call("NotificationRegistryInterface", "unregisterNewExtendedDataOnRevisionHandler", {
			endPointId: this.webSocket.endPointId,
			roid: roid
		}, () => {
			if (callback != null) {
				callback();
			}
		});
	}

	registerProgressHandler(topicId, handler, callback) {
		this.register("NotificationInterface", "progress", handler, () => {
			this.call("NotificationRegistryInterface", "registerProgressHandler", {
				topicId: topicId,
				endPointId: this.webSocket.endPointId
			}, () => {
				if (callback != null) {
					callback();
				} else {
					this.call("NotificationRegistryInterface", "getProgress", {
						topicId: topicId
					}, (state) => {
						handler(topicId, state);
					});
				}
			});
		});
	}

	unregisterProgressHandler(topicId, handler, callback) {
		this.unregister(handler);
		this.call("NotificationRegistryInterface", "unregisterProgressHandler", {
			topicId: topicId,
			endPointId: this.webSocket.endPointId
		}, () => {}).done(callback);
	}

	unregister(listener) {
		for (let i in this.listeners) {
			for (let j in this.listeners[i]) {
				const list = this.listeners[i][j];
				for (let k = 0; k < list.length; k++) {
					if (list[k] === listener) {
						list.splice(k, 1);
						return;
					}
				}
			}
		}
	}

	createRequest(interfaceName, method, data) {
		let object = {};
		object["interface"] = interfaceName;
		object.method = method;
		for (var key in data) {
			if (data[key] instanceof Set) {
				// Convert ES6 Set to an array
				data[key] = Array.from(data[key]);
			}
		}
		object.parameters = data;

		return object;
	}

	getJson(address, data, success, error) {
		const xhr = new XMLHttpRequest();
		xhr.open("POST", address);
		xhr.onerror = () => {
			if (error != null) {
				error("Unknown network error");
			}
		};
		xhr.setRequestHeader("Content-Type", "application/json; charset=UTF-8");
		xhr.onload = (jqXHR, textStatus, errorThrown) => {
			if (xhr.status === 200) {
				let data = "";
				try {
					data = JSON.parse(xhr.responseText);
				} catch (e) {
					if (e instanceof SyntaxError) {
						if (error != null) {
							error(e);
						} else {
							this.notifier.setError(e);
							console.error(e);
						}
					} else {
						console.error(e);
					}
				}
				success(data);
			} else {
				if (error != null) {
					error(jqXHR, textStatus, errorThrown);
				} else {
					this.notifier.setError(textStatus);
					console.error(jqXHR, textStatus, errorThrown);
				}
			}
		};
		xhr.send(JSON.stringify(data));
	}

	multiCall(requests, callback, errorCallback, showBusy, showDone, showError, connectWebSocket) {
		if (!this.webSocket.connected && this.token != null && connectWebSocket) {
			this.webSocket.connect().then(() => {
				this.multiCall(requests, callback, errorCallback, showBusy, showDone, showError);
			});
			return;
		}
		const promise = new BimServerApiPromise();
		let request = null;
		if (requests.length == 1) {
			request = requests[0];
			if (this.interfaceMapping[request[0]] == null) {
				this.log("Interface " + request[0] + " not found");
			}
			request = {
				request: this.createRequest(this.interfaceMapping[request[0]], request[1], request[2])
			};
		} else if (requests.length > 1) {
			let requestObjects = [];
			requests.forEach((request) => {
				if (this.interfaceMapping[request[0]] == null) {
					this.log("Interface " + request[0] + " not found");
				}
				requestObjects.push(this.createRequest(this.interfaceMapping[request[0]], request[1], request[2]));
			});
			request = {
				requests: requestObjects
			};
		} else if (requests.length === 0) {
			promise.fire();
			callback();
		}

		//    		this.notifier.clear();

		if (this.token != null) {
			request.token = this.token;
		}

		let key = requests[0][1];
		requests.forEach((item, index) => {
			if (index > 0) {
				key += "_" + item;
			}
		});

		let showedBusy = false;
		if (showBusy) {
			if (this.lastBusyTimeOut != null) {
				clearTimeout(this.lastBusyTimeOut);
				this.lastBusyTimeOut = null;
			}
			if (typeof window !== 'undefined' && window.setTimeout != null) {
				this.lastBusyTimeOut = window.setTimeout(() => {
					this.notifier.setInfo(this.translate(key + "_BUSY"), -1);
					showedBusy = true;
				}, 200);
			}
		}

		//    		this.notifier.resetStatusQuick();

		this.log("request", request);

		this.getJson(this.address, request, (data) => {
				this.log("response", data);
				let errorsToReport = [];
				if (requests.length == 1) {
					if (showBusy) {
						if (this.lastBusyTimeOut != null) {
							clearTimeout(this.lastBusyTimeOut);
						}
					}
					if (data.response.exception != null) {
						if (showError) {
							if (this.lastTimeOut != null) {
								clearTimeout(this.lastTimeOut);
							}
							this.notifier.setError(data.response.exception.message);
						} else {
							if (showedBusy) {
								this.notifier.resetStatus();
							}
						}
					} else {
						if (showDone) {
							this.notifier.setSuccess(this.translate(key + "_DONE"), 5000);
						} else {
							if (showedBusy) {
								this.notifier.resetStatus();
							}
						}
					}
				} else if (requests.length > 1) {
					data.responses.forEach((response) => {
						if (response.exception != null) {
							if (errorCallback == null) {
								this.notifier.setError(response.exception.message);
							} else {
								errorsToReport.push(response.exception);
							}
						}
					});
				}
				if (errorsToReport.length > 0) {
					errorCallback(errorsToReport);
				} else {
					if (requests.length == 1) {
						callback(data.response);
					} else if (requests.length > 1) {
						callback(data.responses);
					}
				}
				promise.fire();
			},
			(jqXHR, textStatus, errorThrown) => {
				if (textStatus == "abort") {
					// ignore
				} else {
					this.log(errorThrown);
					this.log(textStatus);
					this.log(jqXHR);
					if (this.lastTimeOut != null) {
						clearTimeout(this.lastTimeOut);
					}
					this.notifier.setError(this.translate("ERROR_REMOTE_METHOD_CALL"));
				}
				if (callback != null) {
					const result = {};
					result.error = textStatus;
					result.ok = false;
					callback(result);
				}
				promise.fire();
			});
		return promise;
	}

	getModel(poid, roid, schema, deep, callback, name) {
		const model = new Model(this, poid, roid, schema);
		if (name != null) {
			model.name = name;
		}
		model.load(deep, callback);
		return model;
	}

	createModel(poid, callback) {
		const model = new Model(this, poid);
		model.init(callback);
		return model;
	}

	callWithNoIndication(interfaceName, methodName, data, callback, errorCallback) {
		return this.call(interfaceName, methodName, data, callback, errorCallback, false, false, false);
	}

	callWithFullIndication(interfaceName, methodName, data, callback) {
		return this.call(interfaceName, methodName, data, callback, null, true, true, true);
	}

	callWithUserErrorIndication(action, data, callback) {
		return this.call(null, null, data, callback, null, false, false, true);
	}

	callWithUserErrorAndDoneIndication(action, data, callback) {
		return this.call(null, null, data, callback, null, false, true, true);
	}

	isA(schema, typeSubject, typeName) {
		let isa = false;
		if (typeSubject == typeName) {
			return true;
		}

		let subject = this.schemas[schema][typeSubject];
		if (typeSubject == "GeometryInfo" || typeSubject == "GeometryData") {
			subject = this.schemas.geometry[typeSubject];
		}

		if (subject == null) {
			console.log(typeSubject, "not found");
		}
		subject.superclasses.some((superclass) => {
			if (superclass == typeName) {
				isa = true;
				return true;
			}
			if (this.isA(schema, superclass, typeName)) {
				isa = true;
				return true;
			}
			return false;
		});
		return isa;
	}

	initiateCheckin(project, deserializerOid, callback, errorCallback) {
		this.callWithNoIndication("ServiceInterface", "initiateCheckin", {
			deserializerOid: deserializerOid,
			poid: project.oid
		}, (topicId) => {
			if (callback != null) {
				callback(topicId);
			}
		}, (error) => {
			errorCallback(error);
		});
	}

	checkin(topicId, project, comment, file, deserializerOid, progressListener, success, error) {
		const xhr = new XMLHttpRequest();

		xhr.upload.addEventListener("progress",
			(e) => {
				if (e.lengthComputable) {
					const percentage = Math.round((e.loaded * 100) / e.total);
					progressListener(percentage);
				}
			}, false);

		xhr.addEventListener("load", (event) => {
			const result = JSON.parse(xhr.response);

			if (result.exception == null) {
				if (success != null) {
					success(result.checkinid);
				}
			} else {
				if (error == null) {
					console.error(result.exception);
				} else {
					error(result.exception);
				}
			}
		}, false);

		xhr.open("POST", this.baseUrl + "/upload");

		const formData = new FormData();

		formData.append("token", this.token);
		formData.append("deserializerOid", deserializerOid);
		formData.append("comment", comment);
		formData.append("poid", project.oid);
		formData.append("topicId", topicId);
		formData.append("file", file);

		xhr.send(formData);
	}

	addExtendedData(roid, title, schema, data, success, error) {
		const reader = new FileReader();
		const xhr = new XMLHttpRequest();

		xhr.addEventListener("load", (e) => {
			const result = JSON.parse(xhr.response);

			if (result.exception == null) {
				this.call("ServiceInterface", "addExtendedDataToRevision", {
					roid: roid,
					extendedData: {
						__type: "SExtendedData",
						title: title,
						schemaId: schema.oid,
						fileId: result.fileId
					}
				}, () => {
					success(result.checkinid);
				});
			} else {
				error(result.exception);
			}
		}, false);
		xhr.open("POST", this.baseUrl + "/upload");
		if (typeof data == "File") {
			reader.onload = () => {
				const formData = new FormData();
				formData.append("action", "file");
				formData.append("token", this.token);

				const blob = new Blob([file], {
					type: schema.contentType
				});

				formData.append("file", blob, file.name);
				xhr.send(formData);
			};
			reader.readAsBinaryString(file);
		} else {
			// Assuming data is a Blob
			const formData = new FormData();
			formData.append("action", "file");
			formData.append("token", this.token);
			formData.append("file", data, data.name);
			xhr.send(formData);
		}
	}

	setToken(token, callback, errorCallback) {
		this.token = token;
		this.call("AuthInterface", "getLoggedInUser", {}, (data) => {
			this.user = data;
			this.webSocket.connect(callback);
		}, () => {
			if (errorCallback != null) {
				errorCallback();
			}
		}, true, false, true, false);
	}
	
	callWithWebsocket(interfaceName, methodName, data) {
		var promise = new Promise((resolve, reject) => {
			var id = this.idCounter++;
			this.websocketCalls.set(id, (response) => {
				resolve(response.response.result);
			});
			var request = {
				id: id,
				request: {
					interface: interfaceName,
					method: methodName,
					parameters: data
				}
			};
			if (this.token != null) {
				request.token = this.token;
			}
			this.webSocket.send(request);
		});
		return promise;
	}

	/**
	 * Call a single method, this method delegates to the multiCall method
	 * @param {string} interfaceName - Interface name, e.g. "ServiceInterface"
	 * @param {string} methodName - Methodname, e.g. "addProject"
	 * @param {Object} data - Object with a field per arument
	 * @param {Function} callback - Function to callback, first argument in callback will be the returned object
	 * @param {Function} errorCallback - Function to callback on error
	 * @param {boolean} showBusy - Whether to show busy indication
	 * @param {boolean} showDone - Whether to show done indication
	 * @param {boolean} showError - Whether to show errors
	 * 
	 */
	call(interfaceName, methodName, data, callback, errorCallback, showBusy = true, showDone = false, showError = true, connectWebSocket = true) {
		return this.multiCall([
			[
				interfaceName,
				methodName,
				data
			]
		], (data) => {
			if (data.exception == null) {
				if (callback != null) {
					callback(data.result);
				}
			} else {
				if (errorCallback != null) {
					errorCallback(data.exception);
				}
			}
		}, errorCallback, showBusy, showDone, showError, connectWebSocket);
	}
}

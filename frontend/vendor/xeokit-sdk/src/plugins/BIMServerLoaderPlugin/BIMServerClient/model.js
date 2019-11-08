import BimServerApiPromise from "./bimserverapipromise.js";

/**
 * @private
 */
export default class Model {
	constructor(bimServerApi, poid, roid, schema) {
		this.schema = schema;
		this.bimServerApi = bimServerApi;
		this.poid = poid;
		this.roid = roid;
		this.waiters = [];

		this.objects = {};
		this.objectsByGuid = {};
		this.objectsByName = {};

		this.oidsFetching = {};
		this.guidsFetching = {};
		this.namesFetching = {};

		// Those are only fully loaded types (all of them), should not be stored here if loaded partially
		this.loadedTypes = [];
		this.loadedDeep = false;
		this.changedObjectOids = {};
		this.loading = false;
		this.logging = true;

		this.changes = 0;
		this.changeListeners = [];
	}

	init(callback) {
		callback();
	}

	load(deep, modelLoadCallback) {
		const othis = this;

		if (deep) {
			this.loading = true;
			this.bimServerApi.getJsonStreamingSerializer(function (serializer) {
				othis.bimServerApi.call("ServiceInterface", "download", {
					roids: [othis.roid],
					serializerOid: serializer.oid,
					sync: false
				}, function (topicId) {
					const url = othis.bimServerApi.generateRevisionDownloadUrl({
						topicId: topicId,
						serializerOid: serializer.oid
					});
					othis.bimServerApi.getJson(url, null, function (data) {
						data.objects.forEach(function (object) {
							othis.objects[object._i] = othis.createWrapper(object, object._t);
						});
						othis.loading = false;
						othis.loadedDeep = true;
						othis.waiters.forEach(function (waiter) {
							waiter();
						});
						othis.waiters = [];
						othis.bimServerApi.call("ServiceInterface", "cleanupLongAction", {
							topicId: topicId
						}, function () {
							if (modelLoadCallback != null) {
								modelLoadCallback(othis);
							}
						});
					}, function (error) {
						console.log(error);
					});
				});
			});
		} else {
			if (modelLoadCallback != null) {
				modelLoadCallback(othis);
			}
		}
	}

	// Start a transaction, make sure to wait for the callback to be called, only after that the transaction will be active
	startTransaction(callback) {
		this.bimServerApi.call("LowLevelInterface", "startTransaction", {
			poid: this.poid
		}, (tid) => {
			this.tid = tid;
			callback(tid);
		});
	}

	// Checks whether a transaction is running, if not, it throws an exception, otherwise it return the tid
	checkTransaction() {
		if (this.tid != null) {
			return this.tid;
		}
		throw new Error("No transaction is running, call startTransaction first");
	}

	create(className, object, callback) {
		const tid = this.checkTransaction();
		object._t = className;
		const wrapper = this.createWrapper({}, className);
		this.bimServerApi.call("LowLevelInterface", "createObject", {
			tid: tid,
			className: className
		}, (oid) => {
			wrapper._i = oid;
			this.objects[object._i] = wrapper;
			object._s = 1;
			if (callback != null) {
				callback(object);
			}
		});
		return object;
	}

	reset() {

	}

	commit(comment, callback) {
		const tid = this.checkTransaction();
		this.bimServerApi.call("LowLevelInterface", "commitTransaction", {
			tid: tid,
			comment: comment
		}, function (roid) {
			if (callback != null) {
				callback(roid);
			}
		});
	}

	abort(callback) {
		const tid = this.checkTransaction();
		this.bimServerApi.call("LowLevelInterface", "abortTransaction", {
			tid: tid
		}, function () {
			if (callback != null) {
				callback();
			}
		});
	}

	addChangeListener(changeListener) {
		this.changeListeners.push(changeListener);
	}

	incrementChanges() {
		this.changes++;
		this.changeListeners.forEach((changeListener) => {
			changeListener(this.changes);
		});
	}

	extendClass(wrapperClass, typeName) {
		let realType = this.bimServerApi.schemas[this.schema][typeName];
		if (typeName === "GeometryInfo" || typeName === "GeometryData") {
			realType = this.bimServerApi.schemas.geometry[typeName];
		}
		realType.superclasses.forEach((typeName) => {
			this.extendClass(wrapperClass, typeName);
		});

		const othis = this;

		for (let fieldName in realType.fields) {
			const field = realType.fields[fieldName];
			field.name = fieldName;
			wrapperClass.fields.push(field);
			(function (field, fieldName) {
				if (field.reference) {
					wrapperClass["set" + fieldName.firstUpper() + "Wrapped"] = function (typeName, value) {
						const object = this.object;
						object[fieldName] = {
							_t: typeName,
							value: value
						};
						const tid = othis.checkTransaction();
						const type = othis.bimServerApi.schemas[othis.schema][typeName];
						const wrappedValueType = type.fields.wrappedValue;
						if (wrappedValueType.type === "string") {
							othis.bimServerApi.call("LowLevelInterface", "setWrappedStringAttribute", {
								tid: tid,
								oid: object._i,
								attributeName: fieldName,
								type: typeName,
								value: value
							}, function () {
								if (object.changedFields == null) {
									object.changedFields = {};
								}
								object.changedFields[fieldName] = true;
								othis.changedObjectOids[object.oid] = true;
								othis.incrementChanges();
							});
						}
					};
					wrapperClass["set" + fieldName.firstUpper()] = function (value) {
						const tid = othis.checkTransaction();
						const object = this.object;
						object[fieldName] = value;
						if (value == null) {
							othis.bimServerApi.call("LowLevelInterface", "unsetReference", {
								tid: tid,
								oid: object._i,
								referenceName: fieldName,
							}, function () {
								if (object.changedFields == null) {
									object.changedFields = {};
								}
								object.changedFields[fieldName] = true;
								othis.changedObjectOids[object.oid] = true;
							});
						} else {
							othis.bimServerApi.call("LowLevelInterface", "setReference", {
								tid: tid,
								oid: object._i,
								referenceName: fieldName,
								referenceOid: value._i
							}, function () {
								if (object.changedFields == null) {
									object.changedFields = {};
								}
								object.changedFields[fieldName] = true;
								othis.changedObjectOids[object.oid] = true;
							});
						}
					};
					wrapperClass["add" + fieldName.firstUpper()] = function (value, callback) {
						const object = this.object;
						const tid = othis.checkTransaction();
						if (object[fieldName] == null) {
							object[fieldName] = [];
						}
						object[fieldName].push(value);
						othis.bimServerApi.call("LowLevelInterface", "addReference", {
							tid: tid,
							oid: object._i,
							referenceName: fieldName,
							referenceOid: value._i
						}, function () {
							if (object.changedFields == null) {
								object.changedFields = {};
							}
							object.changedFields[fieldName] = true;
							othis.changedObjectOids[object.oid] = true;
							if (callback != null) {
								callback();
							}
						});
					};
					wrapperClass["remove" + fieldName.firstUpper()] = function (value, callback) {
						const object = this.object;
						const tid = othis.checkTransaction();
						const list = object[fieldName];
						const index = list.indexOf(value);
						list.splice(index, 1);

						othis.bimServerApi.call("LowLevelInterface", "removeReference", {
							tid: tid,
							oid: object._i,
							referenceName: fieldName,
							index: index
						}, function () {
							if (object.changedFields == null) {
								object.changedFields = {};
							}
							object.changedFields[fieldName] = true;
							othis.changedObjectOids[object.oid] = true;
							if (callback != null) {
								callback();
							}
						});
					};
					wrapperClass["get" + fieldName.firstUpper()] = function (callback) {
						const object = this.object;
						const model = this.model;
						const promise = new BimServerApiPromise();
						if (object[fieldName] != null) {
							if (field.many) {
								object[fieldName].forEach(function (item, index) {
									callback(item, index);
								});
							} else {
								callback(object[fieldName]);
							}
							promise.fire();
							return promise;
						}
						const embValue = object["_e" + fieldName];
						if (embValue != null) {
							if (callback != null) {
								callback(embValue);
							}
							promise.fire();
							return promise;
						}
						const value = object["_r" + fieldName];
						if (field.many) {
							if (object[fieldName] == null) {
								object[fieldName] = [];
							}
							if (value != null) {
								model.get(value, function (v) {
									object[fieldName].push(v);
									callback(v, object[fieldName].length - 1);
								}).done(function () {
									promise.fire();
								});
							} else {
								promise.fire();
							}
						} else {
							if (value != null) {
								const ref = othis.objects[value._i];
								if (value._i == -1) {
									callback(null);
									promise.fire();
								} else if (ref == null || ref.object._s == 0) {
									model.get(value._i, function (v) {
										object[fieldName] = v;
										callback(v);
									}).done(function () {
										promise.fire();
									});
								} else {
									object[fieldName] = ref;
									callback(ref);
									promise.fire();
								}
							} else {
								callback(null);
								promise.fire();
							}
						}
						return promise;
					};
				} else {
					wrapperClass["get" + fieldName.firstUpper()] = function (callback) {
						const object = this.object;
						if (field.many) {
							if (object[fieldName] == null) {
								object[fieldName] = [];
							}
//							object[fieldName].push = function () {};
						}
						if (callback != null) {
							callback(object[fieldName]);
						}
						return object[fieldName];
					};
					wrapperClass["set" + fieldName.firstUpper()] = function (value) {
						const object = this.object;
						object[fieldName] = value;
						const tid = othis.checkTransaction();
						if (field.many) {
							othis.bimServerApi.call("LowLevelInterface", "setDoubleAttributes", {
								tid: tid,
								oid: object._i,
								attributeName: fieldName,
								values: value
							}, function () {});
						} else {
							if (value == null) {
								othis.bimServerApi.call("LowLevelInterface", "unsetAttribute", {
									tid: tid,
									oid: object._i,
									attributeName: fieldName
								}, function () {});
							} else if (field.type === "string") {
								othis.bimServerApi.call("LowLevelInterface", "setStringAttribute", {
									tid: tid,
									oid: object._i,
									attributeName: fieldName,
									value: value
								}, function () {});
							} else if (field.type === "double") {
								othis.bimServerApi.call("LowLevelInterface", "setDoubleAttribute", {
									tid: tid,
									oid: object._i,
									attributeName: fieldName,
									value: value
								}, function () {});
							} else if (field.type === "boolean") {
								othis.bimServerApi.call("LowLevelInterface", "setBooleanAttribute", {
									tid: tid,
									oid: object._i,
									attributeName: fieldName,
									value: value
								}, function () {});
							} else if (field.type === "int") {
								othis.bimServerApi.call("LowLevelInterface", "setIntegerAttribute", {
									tid: tid,
									oid: object._i,
									attributeName: fieldName,
									value: value
								}, function () {});
							} else if (field.type === "enum") {
								othis.bimServerApi.call("LowLevelInterface", "setEnumAttribute", {
									tid: tid,
									oid: object._i,
									attributeName: fieldName,
									value: value
								}, function () {});
							} else {
								othis.bimServerApi.log("Unimplemented type " + typeof value);
							}
							object[fieldName] = value;
						}
						if (object.changedFields == null) {
							object.changedFields = {};
						}
						object.changedFields[fieldName] = true;
						othis.changedObjectOids[object.oid] = true;
					};
				}
			})(field, fieldName);
		}
	}

	dumpByType() {
		const mapLoaded = {};
		const mapNotLoaded = {};
		for (let oid in this.objects) {
			const object = this.objects[oid];
			const type = object.getType();
			const counter = mapLoaded[type];
			if (object.object._s == 1) {
				if (counter == null) {
					mapLoaded[type] = 1;
				} else {
					mapLoaded[type] = counter + 1;
				}
			}
			if (object.object._s == 0) {
				const counter = mapNotLoaded[type];
				if (counter == null) {
					mapNotLoaded[type] = 1;
				} else {
					mapNotLoaded[type] = counter + 1;
				}
			}
		}
		console.log("LOADED");
		for (let type in mapLoaded) {
			console.log(type, mapLoaded[type]);
		}
		console.log("NOT_LOADED");
		for (let type in mapNotLoaded) {
			console.log(type, mapNotLoaded[type]);
		}
	}

	getClass(typeName) {
		const othis = this;

		if (this.bimServerApi.classes[typeName] == null) {
			let realType = this.bimServerApi.schemas[this.schema][typeName];
			if (realType == null) {
				if (typeName === "GeometryInfo" || typeName === "GeometryData") {
					realType = this.bimServerApi.schemas.geometry[typeName];
				}
				if (realType == null) {
					throw "Type " + typeName + " not found in schema " + this.schema;
				}
			}

			const wrapperClass = {
				fields: []
			};

			wrapperClass.isA = function (typeName) {
				return othis.bimServerApi.isA(othis.schema, this.object._t, typeName);
			};
			wrapperClass.getType = function () {
				return this.object._t;
			};
			wrapperClass.remove = function (removeCallback) {
				const tid = othis.checkTransaction();
				othis.bimServerApi.call("LowLevelInterface", "removeObject", {
					tid: tid,
					oid: this.object._i
				}, function () {
					if (removeCallback != null) {
						removeCallback();
					}
					delete othis.objects[this.object._i];
				});
			};

			othis.extendClass(wrapperClass, typeName);

			othis.bimServerApi.classes[typeName] = wrapperClass;
		}
		return othis.bimServerApi.classes[typeName];
	}

	createWrapper(object, typeName) {
		if (this.objects[object._i] != null) {
			console.log("Warning!", object);
		}
		if (typeName == null) {
			console.warn("typeName = null", object);
		}
		object.oid = object._i;
		const cl = this.getClass(typeName);
		if (cl == null) {
			console.error("No class found for " + typeName);
		}
		const wrapper = Object.create(cl);
		// transient variables
		wrapper.trans = {
			mode: 2
		};
		wrapper.oid = object.oid;
		wrapper.model = this;
		wrapper.object = object;
		return wrapper;
	}

	size(callback) {
		this.bimServerApi.call("ServiceInterface", "getRevision", {
			roid: this.roid
		}, function (revision) {
			callback(revision.size);
		});
	}

	count(type, includeAllSubTypes, callback) {
		// TODO use includeAllSubTypes
		this.bimServerApi.call("LowLevelInterface", "count", {
			roid: this.roid,
			className: type
		}, function (size) {
			callback(size);
		});
	}

	getByX(methodName, keyname, fetchingMap, targetMap, query, getValueMethod, list, callback) {
		const promise = new BimServerApiPromise();
		if (typeof list == "string" || typeof list == "number") {
			list = [list];
		}
		let len = list.length;
		// Iterating in reverse order because we remove items from this array
		while (len--) {
			const item = list[len];
			if (targetMap[item] != null) {
				// Already loaded? Remove from list and call callback
				const existingObject = targetMap[item].object;
				if (existingObject._s == 1) {
					const index = list.indexOf(item);
					list.splice(index, 1);
					callback(targetMap[item]);
				}
			} else if (fetchingMap[item] != null) {
				// Already loading? Add the callback to the list and remove from fetching list
				fetchingMap[item].push(callback);
				const index = list.indexOf(item);
				list.splice(index, 1);
			}
		}

		const othis = this;
		// Any left?
		if (list.length > 0) {
			list.forEach(function (item) {
				fetchingMap[item] = [];
			});
			othis.bimServerApi.getJsonStreamingSerializer(function (serializer) {
				const request = {
					roids: [othis.roid],
					query: JSON.stringify(query),
					serializerOid: serializer.oid,
					sync: false
				};
				othis.bimServerApi.call("ServiceInterface", "download", request, function (topicId) {
					const url = othis.bimServerApi.generateRevisionDownloadUrl({
						topicId: topicId,
						serializerOid: serializer.oid
					});
					othis.bimServerApi.getJson(url, null, function (data) {
						if (data.objects.length > 0) {
							let done = 0;
							data.objects.forEach(function (object) {
								let wrapper = null;
								if (othis.objects[object._i] != null) {
									wrapper = othis.objects[object._i];
									if (wrapper.object._s != 1) {
										wrapper.object = object;
									}
								} else {
									wrapper = othis.createWrapper(object, object._t);
								}
								const item = getValueMethod(object);
								// Checking the value again, because sometimes serializers send more objects...
								if (list.indexOf(item) != -1) {
									targetMap[item] = wrapper;
									if (fetchingMap[item] != null) {
										fetchingMap[item].forEach(function (cb) {
											cb(wrapper);
										});
										delete fetchingMap[item];
									}
									callback(wrapper);
								}
								done++;
								if (done == data.objects.length) {
									othis.bimServerApi.call("ServiceInterface", "cleanupLongAction", {
										topicId: topicId
									}, function () {
										promise.fire();
									});
								}
							});
						} else {
							othis.bimServerApi.log("Object with " + keyname + " " + list + " not found");
							callback(null);
							promise.fire();
						}
					}, function (error) {
						console.log(error);
					});
				});
			});
		} else {
			promise.fire();
		}
		return promise;
	}

	getByGuids(guids, callback) {
		const query = {
			guids: guids
		};
		return this.getByX("getByGuid", "guid", this.guidsFetching, this.objectsByGuid, query, function (object) {
			return object.GlobalId;
		}, guids, callback);
	}

	get(oids, callback) {
		if (typeof oids == "number") {
			oids = [oids];
		} else if (typeof oids == "string") {
			oids = [parseInt(oids)];
		} else if (Array.isArray(oids)) {
			const newOids = [];
			oids.forEach(function (oid) {
				if (typeof oid == "object") {
					newOids.push(oid._i);
				} else {
					newOids.push(oid);
				}
			});
			oids = newOids;
		}
		const query = {
			oids: oids
		};
		return this.getByX("get", "OID", this.oidsFetching, this.objects, query, function (object) {
			return object._i;
		}, oids, callback);
	}

	getByName(names, callback) {
		const query = {
			names: names
		};
		return this.getByX("getByName", "name", this.namesFetching, this.objectsByName, query, function (object) {
			return object.getName == null ? null : object.getName();
		}, names, callback);
	}

	query(query, callback, errorCallback) {
		const promise = new BimServerApiPromise();
		const fullTypesLoading = {};
		if (query.queries != null) {
			query.queries.forEach((subQuery) => {
				if (subQuery.type != null) {
					if (typeof subQuery.type === "object") {
						fullTypesLoading[subQuery.type.name] = true;
						this.loadedTypes[subQuery.type.name] = {};
						if (subQuery.type.includeAllSubTypes) {
							const schema = this.bimServerApi.schemas[this.schema];
							this.bimServerApi.getAllSubTypes(schema, subQuery.type.name, (subTypeName) => {
								fullTypesLoading[subTypeName] = true;
								this.loadedTypes[subTypeName] = {};
							});
						}
					} else {
						fullTypesLoading[subQuery.type] = true;
						this.loadedTypes[subQuery.type] = {};
						if (subQuery.includeAllSubTypes) {
							const schema = this.bimServerApi.schemas[this.schema];
							this.bimServerApi.getAllSubTypes(schema, subQuery.type, (subTypeName) => {
								fullTypesLoading[subTypeName] = true;
								this.loadedTypes[subTypeName] = {};
							});
						}
					}
				}
			});
		}
		this.bimServerApi.getJsonStreamingSerializer((serializer) => {
			this.bimServerApi.callWithFullIndication("ServiceInterface", "download", {
				roids: [this.roid],
				query: JSON.stringify(query),
				serializerOid: serializer.oid,
				sync: false
			}, (topicId) => {
				let handled = false;
				this.bimServerApi.registerProgressHandler(topicId, (topicId, state) => {
					if (state.title == "Done preparing" && !handled) {
						handled = true;
						const url = this.bimServerApi.generateRevisionDownloadUrl({
							topicId: topicId,
							serializerOid: serializer.oid
						});
						this.bimServerApi.notifier.setInfo(this.bimServerApi.translate("GETTING_MODEL_DATA"), -1);
						this.bimServerApi.getJson(url, null, (data) => {
							//console.log("query", data.objects.length);
							data.objects.forEach((object) => {
								let wrapper = this.objects[object._i];
								if (wrapper == null) {
									wrapper = this.createWrapper(object, object._t);
									this.objects[object._i] = wrapper;
									if (fullTypesLoading[object._t] != null) {
										this.loadedTypes[object._t][wrapper.oid] = wrapper;
									}
								} else {
									if (object._s == 1) {
										wrapper.object = object;
									}
								}
								//										if (othis.loadedTypes[wrapper.getType()] == null) {
								//											othis.loadedTypes[wrapper.getType()] = {};
								//										}
								//										othis.loadedTypes[wrapper.getType()][object._i] = wrapper;
								if (object._s == 1 && callback != null) {
									callback(wrapper);
								}
							});
							//									othis.dumpByType();
							this.bimServerApi.call("ServiceInterface", "cleanupLongAction", {
								topicId: topicId
							}, () => {
								promise.fire();
								this.bimServerApi.notifier.setSuccess(this.bimServerApi.translate("MODEL_DATA_DONE"));
							});
						});
					} else if (state.state == "AS_ERROR") {
						if (errorCallback != null) {
							errorCallback(state.title);
						} else {
							console.error(state.title);
						}
					}
				});
			});
		});
		return promise;
	}

	getAllOfType(type, includeAllSubTypes, callback) {
		const promise = new BimServerApiPromise();
		if (this.loadedDeep) {
			for (let oid in this.objects) {
				const object = this.objects[oid];
				if (object._t == type) {
					callback(object);
				}
			}
			promise.fire();
		} else {
			const types = [];
			types.push(type);
			if (includeAllSubTypes) {
				this.bimServerApi.getAllSubTypes(this.bimServerApi.schemas[this.schema], type, function (subType) {
					types.push(subType);
				});
			}

			const query = {
				queries: []
			};

			types.forEach((type) => {
				if (this.loadedTypes[type] != null) {
					for (let oid in this.loadedTypes[type]) {
						callback(this.loadedTypes[type][oid]);
					}
				} else {
					query.queries.push({
						type: type
					});
				}
			});

			if (query.queries.length > 0) {
				this.bimServerApi.getJsonStreamingSerializer((serializer) => {
					this.bimServerApi.call("ServiceInterface", "download", {
						roids: [this.roid],
						query: JSON.stringify(query),
						serializerOid: serializer.oid,
						sync: false
					}, (topicId) => {
						const url = this.bimServerApi.generateRevisionDownloadUrl({
							topicId: topicId,
							serializerOid: serializer.oid
						});
						this.bimServerApi.getJson(url, null, (data) => {
							if (this.loadedTypes[type] == null) {
								this.loadedTypes[type] = {};
							}
							data.objects.some((object) => {
								if (this.objects[object._i] != null) {
									// Hmm we are doing a query on type, but some objects have already loaded, let's use those instead
									const wrapper = this.objects[object._i];
									if (wrapper.object._s == 1) {
										if (wrapper.isA(type)) {
											this.loadedTypes[type][object._i] = wrapper;
											return callback(wrapper);
										}
									} else {
										// Replace the value with something that's LOADED
										wrapper.object = object;
										if (wrapper.isA(type)) {
											this.loadedTypes[type][object._i] = wrapper;
											return callback(wrapper);
										}
									}
								} else {
									const wrapper = this.createWrapper(object, object._t);
									this.objects[object._i] = wrapper;
									if (wrapper.isA(type) && object._s == 1) {
										this.loadedTypes[type][object._i] = wrapper;
										return callback(wrapper);
									}
								}
							});
							this.bimServerApi.call("ServiceInterface", "cleanupLongAction", {
								topicId: topicId
							}, () => {
								promise.fire();
							});
						}, (error) => {
							console.log(error);
						});
					});
				});
			} else {
				promise.fire();
			}
		}
		return promise;
	}
}

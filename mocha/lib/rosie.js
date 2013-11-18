var Factory = function(constructor) {
  this.construct = constructor;
  this.attrs = {};
  this.sequences = {};
  this.callbacks = [];
};

Factory.prototype = {
  attr: function(attr, value) {
    var callback = typeof value == 'function' ? value : function() { return value; };
    this.attrs[attr] = callback;
    return this;
  },

  sequence: function(attr, callback) {
    var factory = this;
    callback = callback || function(i) { return i; };
    this.attrs[attr] = function() {
      factory.sequences[attr] = factory.sequences[attr] || 0;
      return callback.call(this, ++factory.sequences[attr]);
    };
    return this;
  },

  after: function(callback) {
    this.callbacks.push(callback);
    return this;
  },

  attributes: function(attrs) {
    attrs = attrs || {};
    for(var attr in this.attrs) {
      if(!attrs.hasOwnProperty(attr)) {
        attrs[attr] =  this.attrs[attr]();
      }
    }
    return attrs;
  },

  build: function(attrs) {
    var result = this.attributes(attrs);
    return this.construct ? new this.construct(result) : result;
  },

  extend: function(name) {
    var factory = Factory.factories[name];
    // Copy the parent's constructor
    if (this.construct === undefined) { this.construct = factory.construct; }
    for(var attr in factory.attrs) {
      if(factory.attrs.hasOwnProperty(attr)) {
        this.attrs[attr] = factory.attrs[attr];
      }
    }
    // Copy the parent's callbacks
    for(var i = 0; i < factory.callbacks.length; i++) {
        this.callbacks.push(factory.callbacks[i]);
    }
    return this;
  }
};

Factory.factories = {};

Factory.define = function(name, constructor) {
  var factory = new Factory(constructor);
  this.factories[name] = factory;
  return factory;
};

Factory.build = function(name, attrs, options) {
  var obj = this.factories[name].build(attrs);
  for(var i = 0; i < this.factories[name].callbacks.length; i++) {
      this.factories[name].callbacks[i](obj, options);
  }
  return obj;
};

Factory.buildList = function(name, size, attrs, options) {
  var objs = [];
  for(var i = 0; i < size; i++) {
    objs.push(Factory.build(name, attrs, options));
  }
  return objs;
};

Factory.attributes = function(name, attrs) {
  return this.factories[name].attributes(attrs);
};

if (typeof exports != "undefined") {
  exports.Factory = Factory;
}

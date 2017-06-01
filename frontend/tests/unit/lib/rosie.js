//-- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2017 Jean-Philippe Lang
// Copyright (C) 2010-2013 the ChiliProject Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See doc/COPYRIGHT.rdoc for more details.
//++

var Factory = function(constructor) {
  this.construct = constructor;
  this.attrs = {};
  this.sequences = {};
  this.callbacks = [];
};

function extend(target, options) {
  var name, src, copy;
  // Extend the base object
  for (name in options) {
    src = target[name];
    copy = options[name];

    if (copy !== undefined) {
      target[name] = copy;
    }
  }

  return target;
}

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
    if (typeof this.construct === "object") {
      return extend(Object.create(this.construct), result);
    }

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
Factory.builds = {};

Factory.define = function(name, constructor) {
  var factory = new Factory(constructor);
  if (this.factories[name]) {
    console.log("Warning: Overwriting Factory for " + name);
  }
  this.factories[name] = factory;
  return factory;
};

Factory.all = function (name) {
  return this.builds[name] || [];
};

Factory.build = function(name, attrs, options) {
  var obj = this.factories[name].build(attrs);
  for(var i = 0; i < this.factories[name].callbacks.length; i++) {
      this.factories[name].callbacks[i](obj, options);
  }
  this.builds[name] = this.builds[name] || [];
  this.builds[name].push(obj);
  return obj;
};

Factory.buildList = function(name, size, attrs, options) {
  var objs = [];
  for(var i = 0; i < size; i++) {
    if (i%10000 === 9999) {
      console.log(i + " builds done");
    }
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

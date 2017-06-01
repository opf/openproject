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

function objectSortationEqual(array1, array2) {
    if (array1.length !== array2.length) {
      return false;
    }

    var i;
    for (i = 0; i < array2.length; i += 1) {
      if (array1[i].id !== array2[i].id || array1[i].name !== array2[i].name) {
        return false;
      }
    }

    return true;
}

function objectsortation() {
  var givenSortation = arguments;
  return function (arr) {
    return objectSortationEqual(arr, givenSortation);
  };
}

function sortById(a, b) {
  return a.id > b.id;
}

function objectContainsAll(givenArray) {
  var givenObjects;
  if (arguments.length === 1 && givenArray instanceof Array) {
    givenObjects = givenArray;
  } else {
    givenObjects = Array.prototype.slice.call(arguments);
  }

  givenObjects.sort(sortById);

  return function (arr) {
    arr.sort(sortById);

    return objectSortationEqual(arr, givenObjects);
  };
}

var a = function () {
  return new attributeBuilder();
};

var attributeBuilder = function () {};

var w = this;

function addProperty(obj, attr) {
  Object.defineProperty(obj, "s" + attr,
    {
      get: function () {
        return function (val) {
          this[attr] = val;

          return this;
        };
      }, configurable: true
    }
  );
}

var properties = ["id", "name", "identifier"];

var i;
for (i = 0; i < properties.length; i += 1) {
  addProperty(attributeBuilder.prototype, properties[i]);
}

attributeBuilder.prototype.b = function () {
  return this._result;
};

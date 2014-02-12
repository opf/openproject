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
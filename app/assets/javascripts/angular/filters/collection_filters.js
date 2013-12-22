timelinesApp.filter('getElementById', [function() {
  return function(input, id) {
    var i=0, len=input.length;
    for (; i<len; i++) {
      if (+input[i].id == +id) {
        return input[i];
      }
    }
    return null;
  };
}])

.filter('getElementByAttribute', [function() {
  return function(input, attrName, attr) {
    var i=0, len=input.length;
    for (; i<len; i++) {
      if (+input[i][attrName] == +attr) {
        return input[i];
      }
    }
    return null;
  };
}]);

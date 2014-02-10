angular.module('openproject.uiComponents')

.factory('WorkPackagesHelper', [function() {
  var WorkPackagesHelper = {
    getRowObjectContent: function(object, option) {
      var content = object[option];

      switch(typeof(content)) {
        case 'string':
          return content;
        case 'object':
          return content.name;
        default:
          return '';
      }
    }
  };

  return WorkPackagesHelper;
}]);

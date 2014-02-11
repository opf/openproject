angular.module('openproject.uiComponents')

.factory('WorkPackagesHelper', [function() {
  var WorkPackagesHelper = {
    getRowObjectContent: function(object, option) {
      var content = object[option];

      switch(typeof(content)) {
        case 'object':
          if (content === null) return '';
          return content.name || content.subject;
        default:
          return content || '';
      }
    }
  };

  return WorkPackagesHelper;
}]);

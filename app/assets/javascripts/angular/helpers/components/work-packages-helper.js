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
    },

    getRowObjectCustomValue: function(object, customFieldId) {
      customValue = object.custom_values.filter(function(customValue){
        return customValue.custom_field_id === customFieldId;
      }).first();

      return customValue ? customValue.value : '';
    },

    getSum: function(rows, columnName) {
      var values = rows
        .map(function(row){
          return WorkPackagesHelper.getRowObjectContent(row.object, columnName);
        })
        .filter(function(value) {
          return typeof(value) === 'number';
        });

      if (values.length > 0) {
        sum = values.reduce(function(a, b) {
          return a + b;
        });
      } else {
        sum = null;
      }

      return sum;
    }

  };

  return WorkPackagesHelper;
}]);

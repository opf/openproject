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

    augmentWorkPackageWithData: function(workPackage, attributeName, isCustomValue, data) {
      if (isCustomValue && data) {
        if (workPackage.custom_values) {
          workPackage.custom_values.push(data);
        } else {
          workPackage.custom_values = [data];
        }
      } else {
        workPackage[attributeName] = data;
      }
    },

    getRowObjectCustomValue: function(object, customField) {
      if (!object.custom_values) return null;

      var customValue = object.custom_values.filter(function(customValue){
        return customValue.custom_field_id === customField.id;
      }).first();

      return WorkPackagesHelper.getCustomValue(customField, customValue);
    },

    getCustomValue: function(customField, customValue) {
      if (!customValue) return '';

      switch(customField.field_format) {
        case 'int':
          return parseInt(customValue.value);
        case 'float':
          return parseFloat(customValue.value);
        default:
          return customValue.value;
      }
    },

    getColumnValue: function(rowObject, column) {
      if (column.custom_field) {
        return WorkPackagesHelper.getRowObjectCustomValue(rowObject, column.custom_field);
      } else {
        return WorkPackagesHelper.getRowObjectContent(rowObject, column.name);
      }
    },

    projectRowsToColumn: function(rows, column) {
      return rows.map(function(row){
        return WorkPackagesHelper.getColumnValue(row.object, column);
      });
    },

    getSums: function(rows, column) {
      var values = WorkPackagesHelper.projectRowsToColumn(rows, column)
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

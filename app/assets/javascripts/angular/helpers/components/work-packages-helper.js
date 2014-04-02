angular.module('openproject.workPackages.helpers')

.factory('WorkPackagesHelper', ['dateFilter', 'CustomFieldHelper', function(dateFilter, CustomFieldHelper) {
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

    getFormattedCustomValue: function(object, customField) {
      if (!object.custom_values) return null;

      var customValue = object.custom_values.filter(function(customValue){
        return customValue && customValue.custom_field_id === customField.id;
      }).first();

      if(customValue) {
        return CustomFieldHelper.formatCustomFieldValue(customValue.value, customField.field_format);
      }
    },

    getFormattedColumnData: function(object, column) {
      var value = WorkPackagesHelper.getRowObjectContent(object, column.name);

      return WorkPackagesHelper.formatValue(value, column.meta_data.data_type);
    },

    formatValue: function(value, dataType) {
      switch(dataType) {
        case 'datetime':
          return dateFilter(WorkPackagesHelper.parseDateTime(value), 'medium');
        case 'date':
          return dateFilter(value, 'mediumDate');
        default:
          return value;
      }
    },

    parseDateTime: function(value) {
      return new Date(Date.parse(value.replace(/(A|P)M$/, '')));
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

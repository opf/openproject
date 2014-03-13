angular.module('openproject.timelines.directives')

.constant('WORK_PACKAGE_DATE_COLUMNS', ['start_date', 'due_date'])
.directive('timelineColumn', ['WORK_PACKAGE_DATE_COLUMNS', 'I18n', 'CustomFieldHelper', function(WORK_PACKAGE_DATE_COLUMNS, I18n, CustomFieldHelper) {
  return {
    restrict: 'A',
    scope: {
      rowObject: '=',
      columnName: '=',
      timeline: '=',
      customFields: '='
    },
    templateUrl: '/templates/timelines/timeline_column.html',
    link: function(scope, element) {
      scope.isDateColumn = WORK_PACKAGE_DATE_COLUMNS.indexOf(scope.columnName) !== -1;

      scope.historicalDateKind = getHistoricalDateKind(scope.rowObject, scope.columnName);

      if (CustomFieldHelper.isCustomFieldKey(scope.columnName)) {
        var customFieldId = CustomFieldHelper.getCustomFieldId(scope.columnName), customFieldName, customFieldFormat;

        // watch custom field because they are loaded after the rows are being iterated
        scope.$watch('timeline.custom_fields', function() {
          scope.columnData = getCustomFieldColumnData(scope.rowObject, scope.columnName, scope.customFields, customFieldId, scope.timeline.users);
        });
      } else {
        scope.columnData = getColumnData();
      }

      function getHistoricalDateKind(object, value) {
        if (!object.does_historical_differ()) return;

        var newDate = object[value];
        var oldDate = object.historical()[value];

        if (oldDate && newDate) {
          return (newDate < oldDate ? 'postponed' : 'preponed');
        }
        return "changed";
      }


      function getColumnData() {
        var map = {
          "type": "getTypeName",
          "status": "getStatusName",
          "responsible": "getResponsibleName",
          "assigned_to": "getAssignedName",
          "project": "getProjectName"
        };

        switch(scope.columnName) {
          case 'start_date':
            return scope.rowObject.start_date;
          case 'due_date':
            return scope.rowObject.due_date;
          default:
            return scope.rowObject[map[scope.columnName]]();
        }
      }

      function getCustomFieldColumnData(object, value, customFields, customFieldId, users) {
        if (customFields && customFields[customFieldId]) {
          var customField = customFields[customFieldId];

          return CustomFieldHelper.formatCustomFieldValue(object[value], customField.field_format, users);
        }
      }
    }
  };
}]);

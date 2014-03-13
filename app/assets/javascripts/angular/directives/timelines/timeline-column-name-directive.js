angular.module('openproject.timelines.directives')

.directive('timelineColumnName', ['I18n', 'CustomFieldHelper', function(I18n, CustomFieldHelper) {
  return {
    restrict: 'A',
    scope: {
      columnName: '=',
      customFields: '=',
      localePrefix: '@'
    },
    link: function(scope, element) {
      scope.$watch('customFields', function(){
        if (CustomFieldHelper.isCustomFieldKey(scope.columnName)) {
          var customFieldId = CustomFieldHelper.getCustomFieldId(scope.columnName);
          if (scope.customFields && scope.customFields[customFieldId]) {
            element.html(scope.customFields[customFieldId].name);
          }
        } else {
          element.html(I18n.t(scope.localePrefix + '.' + scope.columnName));
        }
      });

    }
  };
}]);

angular.module('openproject.timelines.directives')

.constant('WORK_PACKAGE_DATE_COLUMNS', ['start_date', 'due_date'])
.directive('timelineColumn', ['WORK_PACKAGE_DATE_COLUMNS', 'I18n', function(WORK_PACKAGE_DATE_COLUMNS, I18n) {
  return {
    restrict: 'A',
    scope: {
      rowObject: '=',
      columnName: '=',
    },
    templateUrl: '/templates/timelines/timeline_column.html',
    link: function(scope, element) {
      scope.isDateColumn = WORK_PACKAGE_DATE_COLUMNS.indexOf(scope.columnName) !== -1;
    }
  };
}]);

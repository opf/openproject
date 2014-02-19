angular.module('openproject.workPackages.directives')

.directive('queryColumns', ['WorkPackagesTableHelper', 'WorkPackageService', function(WorkPackagesTableHelper, WorkPackageService) {

  return {
    restrict: 'E',
    replace: true,
    templateUrl: '/templates/work_packages/query_columns.html',
    compile: function(tElement) {
      return {
        pre: function(scope) {
          scope.moveColumns = function (columnNames, fromColumns, toColumns) {
            angular.forEach(columnNames, function(columnName){
              removeColumn(columnName, fromColumns, function(removedColumn){
                toColumns.push(removedColumn);
              })
            });

            extendRowsWithColumnData(columnNames);
          };

          function extendRowsWithColumnData(columnNames) {
            var newColumns = WorkPackagesTableHelper.selectColumnsByName(scope.columns, columnNames);

            // work package rows
            angular.forEach(newColumns, function(column){
              WorkPackageService.augmentWorkPackagesWithColumnData(
                scope.rows.map(function(row) {
                  return row.object;
                }),
                column
              );
            });
          }

          function removeColumn(columnName, columns, callback) {
            callback.call(this, columns.splice(WorkPackagesTableHelper.getColumnIndexByName(columns, columnName), 1).first());
          }

          function getColumnIndexes(columnNames, columns) {
            return columnNames
              .map(function(name) {
                return WorkPackagesTableHelper.getColumnIndexByName(columns, name);
              })
              .filter(function(columnIndex){
                return columnIndex !== -1;
              });
          }

        }
      };
    }
  };
}]);

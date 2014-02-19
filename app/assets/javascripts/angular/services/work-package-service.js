angular.module('openproject.services')

.service('WorkPackageService', ['$http', 'PathHelper', 'WorkPackagesHelper', function($http, PathHelper, WorkPackagesHelper) {

  var WorkPackageService = {
    getWorkPackages: function(projectId, query) {
      var url = projectId ? PathHelper.projectWorkPackagesPath(projectId) : PathHelper.workPackagesPath();

      var params =  {
        'c[]': query.selectedColumns.map(function(column){
          return columnName;
        }),
        'group_by': query.group_by
      };

      return WorkPackageService.doQuery(url, params);
    },

    loadWorkPackageColumnData: function(workPackages, columnName) {
      var url = PathHelper.workPackagesColumnDataPath();

      var params = {
        'ids[]': workPackages.map(function(workPackage){
          return workPackage.id;
        }),
        column_name: columnName
      };

      return WorkPackageService.doQuery(url, params);
    },

    augmentWorkPackagesWithColumnData: function(workPackages, column) {
      var columnName = column.name;

      return WorkPackageService.loadWorkPackageColumnData(workPackages, column.name)
        .then(function(columnData){
          angular.forEach(workPackages, function(workPackage, index) {
            WorkPackagesHelper.augmentWorkPackageWithData(workPackage, column.name, !!column.custom_field, columnData[index]);
          });

          return workPackages;
        });
    },

    doQuery: function(url, params) {
      return $http({
        method: 'GET',
        url: url,
        params: params,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'
      }}).then(function(response){
        return response.data;
      });
    }
  };

  return WorkPackageService;
}]);

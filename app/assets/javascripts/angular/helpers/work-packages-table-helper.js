angular.module('openproject.workPackages.helpers')

.factory('WorkPackagesTableHelper', ['WorkPackagesHelper', function(WorkPackagesHelper) {
  var WorkPackagesTableHelper = {
    /* builds rows from work packages, see IssuesHelper */
    getRows: function(workPackages, groupBy) {
      var rows = [], ancestors = [];

      angular.forEach(workPackages, function(workPackage, i) {
        while(ancestors.length > 0 && workPackage.parent_id !== ancestors.last().object.id) {
          ancestors.pop();
        }

        var row = {
          level: ancestors.length,
          groupName: WorkPackagesHelper.getRowObjectContent(workPackage, groupBy),
          parent: ancestors.last(),
          ancestors: ancestors.slice(0),
          object: workPackage
        };

        rows.push(row);

        if (!workPackage['leaf?']) ancestors.push(row);
      });

      return rows;
    }

  };

  return WorkPackagesTableHelper;
}]);

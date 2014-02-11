angular.module('openproject.workPackages.helpers')

.factory('WorkPackagesTableHelper', ['WorkPackagesHelper', function(WorkPackagesHelper) {
  var WorkPackagesTableHelper = {
    /* builds rows from work packages, see IssuesHelper */
    getRows: function(workPackages, groupBy) {
      var rows = [], ancestors = [];
      var currentGroup, allGroups = [], groupIndex = -1;

      angular.forEach(workPackages, function(workPackage, i) {
        while(ancestors.length > 0 && workPackage.parent_id !== ancestors.last().object.id) {
          // this helper method only reflects hierarchies if nested work packages follow one another
          ancestors.pop();
        }

        // manage groups

        // this helper method assumes that the work packages are passed in in blocks each of which consisting of work packages which belong to one group

        currentGroup = WorkPackagesHelper.getRowObjectContent(workPackage, groupBy);

        if(allGroups.indexOf(currentGroup) === -1) {
          allGroups.push(currentGroup);
          groupIndex++;
        }

        // compose row

        var row = {
          level: ancestors.length,
          groupIndex: groupIndex,
          groupName: currentGroup,
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

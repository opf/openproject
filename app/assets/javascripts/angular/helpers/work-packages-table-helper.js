openprojectApp.factory('WorkPackagesTableHelper', [function() {
  var WorkPackagesTableHelper = {
    getRows: function(workPackages) {
      return workPackages.map(function(workPackage){
        return {
          level: 0, // TODO retrieve level from ancestors size
          group: 0,
          groupName: '',
          parent: null,
          ancestors: [],
          object: workPackage
        };
      });
    }
  };

  return WorkPackagesTableHelper;
}]);

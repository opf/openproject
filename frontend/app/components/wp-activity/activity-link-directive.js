function activityLink() {
  return {
    restrict: 'E',
    templateUrl: '/templates/work_packages/activities/_link.html',
    scope: {
      workPackage: '=',
      activityNo: '=',
      onBlur: '&',
      onFocus: '&'
    },
    link: function(scope) {
      scope.workPackageId = scope.workPackage.id;
      scope.activityHtmlId = 'activity-' + scope.activityNo;
    }
  };
}

angular
  .module('openproject.workPackages.activities')
  .directive('activityLink', activityLink);

function activityLink() {
  return {
    restrict: 'E',
    template: `
    <a id ="{{ activityHtmlId }}-link"
       ng-bind="'#' + activityNo"
       ui-sref="work-packages.show.activity({ workPackageId: workPackageId, '#': activityHtmlId})">
    </a>
    `,
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

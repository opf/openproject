module.exports = function() {
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
      scope.workPackageId = scope.workPackage.props.id;
      scope.activityHtmlId = 'activity-' + scope.activityNo;
    }
  };
};

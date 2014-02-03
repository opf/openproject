openprojectApp.directive('timelineContainer', [function() {
  getInitialOutlineExpansion = function(timelineOptions) {
    initialOutlineExpansion = timelineOptions.initial_outline_expansion;
    if (initialOutlineExpansion && initialOutlineExpansion >= 0) {
      return initialOutlineExpansion;
    } else {
      return 0;
    }
  };

  return {
    restrict: 'E',
    replace: true,
    transclude: true,
    template: '<div ng-transclude id="{{timelineContainerElementId}}"/>',
    link: function(scope) {
      scope.timelineContainerElementId = 'timeline-container-' + (++scope.timelineContainerCount);

      // Hide charts until tables are drawn
      scope.underConstruction = true;

      // Create timeline object
      scope.timeline = Timeline.create(scope.timelineOptions);

      // Set initial expansion index
      scope.timeline.expansionIndex = getInitialOutlineExpansion(scope.timelineOptions);
    }
  };
}]);

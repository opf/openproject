openprojectApp.directive('timelineContainer', [function() {
  return {
    restrict: 'E',
    replace: true,
    transclude: true,
    template: '<div ng-transclude id="{{timelineContainerElementId}}"/>',
    link: function(scope) {
      scope.timelineContainerElementId = 'timeline-container-' + (++scope.timelineContainerCount);
    }
  };
}]);

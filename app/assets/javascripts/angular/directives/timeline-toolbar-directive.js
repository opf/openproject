openprojectApp.directive('timelineToolbar', [function() {

  return {
    restrict: 'E',
    replace: true,
    templateUrl: '/templates/timelines/toolbar.html',
    link: function(scope) {
      scope.currentScaleName = 'monthly';

      scope.updateToolbar = function() {
        scope.slider.slider('value', scope.timeline.zoomIndex + 1);
        scope.currentOutlineLevel = Timeline.OUTLINE_LEVELS[scope.timeline.expansionIndex];
        scope.currentScaleName = Timeline.ZOOM_SCALES[scope.timeline.zoomIndex];
      };

      scope.increaseZoom = function() {
        if(scope.currentScaleIndex < Object.keys(Timeline.ZOOM_CONFIGURATIONS).length - 1) {
          scope.currentScaleIndex++;
        }
      };
      scope.decreaseZoom = function() {
        if(scope.currentScaleIndex > 0) {
          scope.currentScaleIndex--;
        }
      };

      scope.$watch('currentScaleName', function(newScaleName, oldScaleName){
        if (newScaleName !== oldScaleName) {
          scope.currentScale = Timeline.ZOOM_CONFIGURATIONS[scope.currentScaleName].scale;
          scope.timeline.scale = scope.currentScale;

          scope.currentScaleIndex = Timeline.ZOOM_SCALES.indexOf(scope.currentScaleName);
          scope.slider.slider('value', scope.currentScaleIndex + 1);

          scope.timeline.zoom(scope.currentScaleIndex); // TODO replace event-driven adaption by bindings
        }
      });

      scope.$watch('currentOutlineLevel', function(outlineLevel, formerLevel) {
        if (outlineLevel !== formerLevel) {
          scope.timeline.expansionIndex = Timeline.OUTLINE_LEVELS.indexOf(outlineLevel);
          scope.timeline.expandToOutlineLevel(outlineLevel); // TODO replace event-driven adaption by bindings
        }
      });
    }
  };
}]);

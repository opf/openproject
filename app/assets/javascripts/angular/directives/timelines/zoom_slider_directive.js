timelinesApp.directive('zoomSlider', function() {
  return {
    restrict: 'A',
    link: function(scope, element, attributes) {
      scope.currentScaleIndex = Timeline.ZOOM_SCALES.indexOf(scope.currentScaleName);
      scope.slider = element.slider({
        min: 1,
        max: Timeline.ZOOM_SCALES.length,
        range: 'min',
        value: scope.currentScaleIndex + 1,
        slide: function(event, ui) {
          scope.currentScaleIndex = ui.value - 1;
          scope.$apply();
        },
        change: function(event, ui) {
          scope.updateScaleIndex(ui.value - 1);
        }
      }).css({
        // top right bottom left
        'margin': '4px 6px 3px'
      });

      // Slider
      // TODO integrate angular-ui-slider

      scope.updateScaleIndex = function(scaleIndex) {
        scope.currentScaleIndex = scaleIndex;

        newScaleName = Timeline.ZOOM_SCALES[scaleIndex];
        if (scope.currentScaleName !== newScaleName) {
          scope.currentScaleName = newScaleName;
        }
      };

      scope.$watch('currentScaleIndex', function(newIndex){
        scope.updateScaleIndex(newIndex);
      });

      scope.$watch('currentScaleName', function(newScaleName, oldScaleName){
        if (newScaleName !== oldScaleName) {
          scope.currentScale = Timeline.ZOOM_CONFIGURATIONS[scope.currentScaleName].scale;
          scope.timeline.scale = scope.currentScale;

          scope.currentScaleIndex = Timeline.ZOOM_SCALES.indexOf(scope.currentScaleName);
          scope.slider.slider('value', scope.currentScaleIndex + 1);

          scope.timeline.zoom(scope.currentScaleIndex);

        }
      });

    }
  };
});


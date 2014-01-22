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
          scope.currentScaleIndex = ui.value - 1;
        }
      }).css({
        // top right bottom left
        'margin': '4px 6px 3px'
      });

      // Slider
      // TODO integrate angular-ui-slider

      scope.$watch('currentScaleIndex', function(newIndex){
        scope.currentScaleIndex = newIndex;

        newScaleName = Timeline.ZOOM_SCALES[newIndex];
        if (scope.currentScaleName !== newScaleName) {
          scope.currentScaleName = newScaleName;
        }
      });

    }
  };
});


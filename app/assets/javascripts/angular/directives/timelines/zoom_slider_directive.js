timelinesApp.directive('zoomSlider', function() {
  return {
    restrict: 'A',
    link: function(scope, element, attributes) {
      scope.currentScaleIndex = Timeline.ZOOM_SCALES.indexOf(scope.currentScale);
      scope.slider = element.slider({
        min: 1,
        max: Timeline.ZOOM_SCALES.length,
        range: 'min',
        value: scope.currentScaleIndex + 1,
        slide: function(event, ui) {
          scope.currentScaleIndex = ui.value - 1;
        },
        change: function(event, ui) {
          scope.currentScaleIndex = ui.value - 1;
          scope.timeline.zoom(ui.value - 1);
        }
      }).css({
        // top right bottom left
        'margin': '4px 6px 3px'
      });

      // Slider
      // TODO integrate angular-ui-slider
      scope.getCurrentScaleLevel = function() {
        return scope.slider.slider('value');
      };
      scope.setCurrentScaleLevel = function(value) {
        scope.slider.slider('value', value);
      };

      scope.$watch('currentScaleIndex', function(){
        scope.currentScale = Timeline.ZOOM_SCALES[scope.currentScaleIndex];
      });
      scope.$watch('currentScale', function(){
        scope.currentScaleIndex = Timeline.ZOOM_SCALES.indexOf(scope.currentScale);
        // scope.setCurrentScaleLevel(scope.currentScaleIndex);
      });

    }
  };
});


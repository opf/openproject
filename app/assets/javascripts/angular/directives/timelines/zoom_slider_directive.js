timelinesApp.directive('zoomSlider', function() {
  return {
    restrict: 'A',
    link: function(scope, element, attributes) {
      currentScaleIndex = Timeline.ZOOM_SCALES.indexOf(scope.currentScale);
      scope.slider = element.slider({
        min: 1,
        max: Timeline.ZOOM_SCALES.length,
        range: 'min',
        value: currentScaleIndex + 1,
        slide: function(event, ui) {
          currentScaleIndex = ui.value - 1;
        },
        change: function(event, ui) {
          currentScaleIndex = ui.value - 1;
          scope.timeline.zoom(ui.value - 1);
        }
      }).css({
        // top right bottom left
        'margin': '4px 6px 3px'
      });
    }
  };
});


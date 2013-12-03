timelinesApp.directive('zoomSlider', function() {
  return {
    restrict: 'A',
    link: function(scope, element, attributes) {
      zooms = jQuery('select[name="zooms"]');
      element.slider({
        min: 1,
        max: Timeline.ZOOM_SCALES.length,
        range: 'min',
        value: zooms[0].selectedIndex + 1,
        slide: function(event, ui) {
          zooms[0].selectedIndex = ui.value - 1;
        },
        change: function(event, ui) {
          zooms[0].selectedIndex = ui.value - 1;
          timeline.zoom(ui.value - 1);
        }
      }).css({
        // top right bottom left
        'margin': '4px 6px 3px'
      });
    }
  };
});

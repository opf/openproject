jQuery(function($) {
  var tooltipTriggers = $('.advanced-tooltip-trigger');
  tooltipTriggers.each(function (index, el) {
    var tooltip = $("#" + $(el).attr('aria-describedby'));

    $(el).bind('mouseover focus', function () {
      var top = $(this).offset().top - $(window).scrollTop();
      // Adjust top for small elements
        var POINTER_HEIGHT = 16.5;
        var middle = $(this).outerHeight() / 2;
        if (middle < POINTER_HEIGHT) top -= POINTER_HEIGHT - middle;

      // On the left side of the element + 5px Distance
      var left = $(this).offset().left + $(this).width() + 5;

      tooltip.css({'opacity': 1, 'visibility': 'visible', 'top': top, 'left': left});
    }).bind('mouseout focusout', function () {
      tooltip.css({'opacity': 0, 'visibility': 'hidden'});
    });
  });
});

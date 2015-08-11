jQuery(function($) {
  var tooltipTriggers = $('.advanced-tooltip-trigger');
  tooltipTriggers.each(function (index, el) {
    var tooltip = $("#" + $(el).attr('aria-describedby'));
    $(el).bind('mouseover focus', function () {
      var top = $(this).offset().top - $(window).scrollTop();
      tooltip.css({'opacity': 1, 'visibility': 'visible', 'top': top});
    }).bind('mouseout focusout', function () {
      tooltip.css({'opacity': 0, 'visibility': 'hidden'});
    });
  });
});

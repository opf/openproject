jQuery(function($) {
  var tooltipTriggers = $('.advanced-tooltip-trigger');
  tooltipTriggers.each(function (index, el) {
    var tooltip = $($(el).data('tooltip-target'));
    $(el).mouseover(function () {
      var top = $(this).offset().top - $(window).scrollTop();
      tooltip.css({'opacity': 1, 'visibility': 'visible', 'top': top});
    }).mouseout(function () {
      tooltip.css({'opacity': 0, 'visibility': 'hidden'});
    });
  });
});

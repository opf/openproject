jQuery(function($) {
  var tooltipTriggers = $('.advanced-tooltip-trigger');
  tooltipTriggers.each(function createTooltip(index, el) {
    var content = $($(el).data('tooltip-target'))[0].outerHTML;
    $(el).mouseover(function () {
      var width = $(this).outerWidth(true);
      $(this).wrap('<div class="advanced-tooltip-wraper"/>');
      $(this).after(content).next().css({'left': (width) + 'px', 'top': 0});
    }).mouseout(function () {
      $(this).unwrap();
      $(this).next().remove();
    });
  });
});

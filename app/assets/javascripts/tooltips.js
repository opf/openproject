jQuery(function($) {
  var tooltipElements = $('.advanced-tooltip');
  var input = $('input[id^="new_password"]');
  if(tooltipElements.length){
    tooltipElements.each(function createTooltip() {
      input.focusin(function () {
        $(this).parent().parent().addClass('tooltip-visible');
      }).focusout(function () {
        $(this).parent().parent().removeClass('tooltip-visible');
      });
    });
  }
});

(function($) {

  var showTooltips = function(options) {
    settings = $.extend(true,
                                  {},
                                  { element  : '' },
                                  options);

    jQuery(settings.element)
    .focusin(function () {
      jQuery(this).parent().parent().addClass('tooltip-visible');
    })
    .focusout(function () {
      jQuery(this).parent().parent().removeClass('tooltip-visible');
    });
  }
}(jQuery))

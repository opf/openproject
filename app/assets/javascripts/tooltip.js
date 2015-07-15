(function($) {

  var showTooltips = function(options) {
    var settings = $.extend(true,
                                        {},
                                        { element  : '' },
                                        options);

    $(settings.element).focusin(function () {
      $(this).parent().parent().addClass('tooltip-visible');
    }).focusout(function () {
      $(this).parent().parent().removeClass('tooltip-visible');
    });
  }
}(jQuery))

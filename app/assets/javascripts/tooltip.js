var showTooltips = function(options) {
  this.init = function() {
    this.settings = jQuery.extend({}, defaultOptions, options);

    jQuery(this.settings.element)
    .focusin(function () {
      jQuery(this).parent().parent().addClass('tooltip-visible');
    })
    .focusout(function () {
      jQuery(this).parent().parent().removeClass('tooltip-visible');
    });
  };

  var defaultOptions = {
    element  : '.form--field-container input',
  };

  this.init();
}

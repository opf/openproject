/*
 * Expands Redmine's current menu
 */
(function($) {
  $.menu_expand = function(options) {
      var opts = $.extend({
          menu: '#main-menu',
          selectedClass: '.selected'
      }, options);

      if (options.item !== undefined) {
        options.item.toggleClass("open").siblings("ul").show();
      }
      else {
        $(opts.menu +' '+ opts.selectedClass).toggleClass("open").siblings("ul").show();
      }

  }})(jQuery);

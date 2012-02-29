jQuery.fn.reverse = [].reverse;
(function($){
  $.fn.adjustBreadcrumbToWindowSize = function(){
    var breadcrumbElements = this.find(' > li');
    var breadcrumb = this;
    var lastChanged;

    if (breadcrumb.breadcrumbOutOfBounds()){
      breadcrumbElements.each(function(index) {
        if (breadcrumb.breadcrumbOutOfBounds()){
          if (!$(this).find(' > a').hasClass('nocut')){
              $(this).addClass('cutme ellipsis');
          }
        }
        else {
          return false;
        }
      });
    }
    else {
      breadcrumbElements.reverse().each(function(index) {
        if (!breadcrumb.breadcrumbOutOfBounds()){
          if (!$(this).find(' > a').hasClass('nocut')){
            $(this).removeClass('cutme ellipsis');
            lastChanged = $(this);
          }
        }
      });

      if (breadcrumb.breadcrumbOutOfBounds()){
        if (lastChanged != undefined){
          lastChanged.addClass('cutme ellipsis');
          return false;
        }
      }
    }
  };

  $.fn.breadcrumbOutOfBounds = function(){
    var lastElement = this.find(' > li').last();
    var rightCorner = lastElement.width() + lastElement.offset().left;
    var windowSize = jQuery(window).width();

    if ((Math.max(1000,windowSize) - rightCorner) < 10) {
      return true;
    }
    else {
      return false;
    }
  };
})(jQuery)

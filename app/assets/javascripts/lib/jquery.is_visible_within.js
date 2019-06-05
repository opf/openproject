/**
 * Copyright 2012, Digital Fusion
 * Licensed under the MIT license.
 * http://teamdf.com/jquery-plugins/license/
 *
 * @author Sam Sehnert
 * @desc A small plugin that checks whether elements are within
 * the user visible viewport of a web browser.
 * only accounts for vertical position, not horizontal.
 *
 * Extended here to include an optional container used as parent,
 * as the original plugin only supports window.
 */
(function ($) {

  $.fn.isVisibleWithin = function (container, partial, hidden) {
      var $t = $(this).eq(0),
          t = $t.get(0),
          $w = (container != null ? container : $(window)),
          viewTop = (container != null ? container.offset().top : $w.scrollTop()),
          viewBottom = viewTop + $w.height(),
          _top = $t.offset().top,
          _bottom = _top + $t.height(),
          compareTop = partial === true ? _bottom : _top,
          compareBottom = partial === true ? _top : _bottom,
          clientSize = hidden === true ? t.offsetWidth * t.offsetHeight : true;
      return !!clientSize && ((compareBottom <= viewBottom) && (compareTop >= viewTop));
  };

})(jQuery);

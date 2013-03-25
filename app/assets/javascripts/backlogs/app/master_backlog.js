/*jslint indent: 2*/
/*globals window, document, jQuery, RB*/

// Initialize the backlogs after DOM is loaded
jQuery(function ($) {

  // Initialize each backlog
  $('.backlog').each(function (index) {
    // 'this' refers to an element with class="backlog"
    RB.Factory.initialize(RB.Backlog, this);
  });

  // Workaround for IE7
  if ($.browser.msie && $.browser.version <= 7) {
    var z = 50;
    $('.backlog, .header').each(function () {
      $(this).css('z-index', z);
      z -= 1;
    });
  }
});

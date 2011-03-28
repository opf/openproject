/*jslint indent: 2*/
/*globals window, document, jQuery, RB*/

// Initialize the backlogs after DOM is loaded
jQuery(function ($) {

  // Initialize each backlog
  $('.backlog').each(function (index) {
    // 'this' refers to an element with class="backlog"
    RB.Factory.initialize(RB.Backlog, this);
  });

  RB.BacklogsUpdater.start();

  // Workaround for IE7
  if ($.browser.msie && $.browser.version <= 7) {
    var z = 2000;
    $('.backlog, .header').each(function () {
      $(this).css('z-index', z);
      z -= 1;
    });
  }
});

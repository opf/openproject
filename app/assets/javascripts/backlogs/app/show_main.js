/*jslint indent: 2*/
/*globals jQuery, RB*/

// Initialize everything after DOM is loaded
jQuery(function ($) {
  var defaultDialogColor; // this var is used as cache for some computation in
                          // the inner function. -> Do not move to where it
                          // actually belongs!

  RB.Factory.initialize(RB.Taskboard, $('#taskboard'));

  $('#assigned_to_id_options').change(function () {
    var selected = $(this).children(':selected');
    if (!defaultDialogColor) {
      defaultDialogColor = $('<div id="rb"><div class="model issue task"></div></div>').children().css('background-color');
    }
    $(this).parents('.ui-dialog').css('background-color', selected.attr('color') || defaultDialogColor);
  });
});

/*jslint indent: 2*/
/*globals window, document, jQuery, RB*/

// Initialize everything after DOM is loaded
jQuery(function ($) {
  var showCharts, defaultDialogColor;

  showCharts = function (e) {
    e.preventDefault();

    if ($("#charts").length === 0) {
      $("<div id='charts'></div>").appendTo("body");
    }
    $('#charts').html("<div class='loading'>Loading data...</div>");
    $('#charts').load(RB.urlFor('show_burndown_chart', {id: RB.constants.sprint_id}));
    $('#charts').dialog({
      buttons: {
        Close: function () {
          $(this).dialog("close");
        }
      },
      modal: true,
      title: 'Charts',
      height: 790,
      width: 710
    });
  };

  RB.Factory.initialize(RB.Taskboard, $('#taskboard'));
  RB.TaskboardUpdater.start();

  // Capture 'click' instead of 'mouseup' so we can preventDefault();
  $('#show_charts').click(showCharts);

  $('#assigned_to_id_options').change(function () {
    var selected = $(this).children(':selected');
    if (!defaultDialogColor) {
      defaultDialogColor = $('<div id="rb"><div class="model issue task"></div></div>').children().css('background-color');
    }
    $(this).parents('.ui-dialog').css('background-color', selected.attr('color') || defaultDialogColor);
  });
});

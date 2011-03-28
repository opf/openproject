/*jslint indent: 2*/
/*globals window, document, jQuery, RB*/

// Initialize everything after DOM is loaded
jQuery(function ($) {
  var showCharts = function (e) {
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
    $(this).parents('.ui-dialog').css('background-color', $(this).children(':selected').attr('color'));
  });
});

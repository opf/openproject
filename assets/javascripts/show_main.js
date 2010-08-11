// Initialize everything after DOM is loaded
$(function() {  
  var board = RB.Factory.initialize(RB.Taskboard, $('#taskboard'));
  RB.TaskboardUpdater.start();

  // Capture 'click' instead of 'mouseup' so we can preventDefault();
  $('#show_charts').bind('click', RB.showCharts);
  
  $('#assigned_to_id_options').bind('change', function(){
    $(this).parents('.ui-dialog').css('background-color', $(this).children(':selected').attr('color'));
  });
});

RB.showCharts = function(event){
  event.preventDefault();
  $('#charts').html("<div class='loading'>Loading data...</div>");
  $('#charts').load(RB.urlFor['show_charts'] + '?project_id=' + RB.constants['project_id'] + '&sprint_id=' + RB.constants.sprint_id);
  $('#charts').dialog({ 
                        buttons: { "Close": function() { $(this).dialog("close") } },
                        height: 790,
                        modal: true, 
                        title: 'Charts', 
                        width: 710 
                     });
}
// Initialize the backlogs after DOM is loaded
$(function() {
  // Initialize each backlog
  $('.backlog').each(function(index){
    backlog = RB.Factory.initialize(RB.Backlog, this); // 'this' refers to an element with class="backlog"
  });
  
  // RB.lastUpdated = new Date($('#last_updated').text());
  // console.log(RB.lastUpdated);
  $('#refresh').bind('click', RB.indexMain.handleRefreshClick);
});

RB.indexMain = RB.Object.create({
  
  handleRefreshClick: function(event, ui){
    // var date = RB.lastUpdated;
    // var afterString = date.getUTCFullYear() + "-" + date.getUTCMonth() + "-" + date.getUTCDate() + " " +
    //                   date.getUTCHours() + ":" + date.getUTCMinutes() + ":" + date.getUTCSeconds();
    
    $.ajax({
      type: "GET",
      url: RB.urlFor['list_stories'],
      data: { after     : $('#last_updated').text(), // afterString,
              project_id: RB.constants.project_id
            },
      complete: RB.indexMain.refresh
    });
  },
  
  refresh: function(xhr, statusText){
    var stories = $(xhr.responseText).children('.story');
    $('#last_updated').text(($(xhr.responseText).children('#last_updated').text()));
    
    stories.each(function(i, v){
      var updated = RB.Factory.initialize(RB.Story, v);
      var previous = updated.$.find(".previous").text();
      var old = $('#story_' + updated.getID()).data('this');
      
      old.$.html(updated.$.html());
      if(previous.length > 0){
        old.$.insertAfter($("#story_" + previous));
      } else {
        old.$.insertBefore(old.$.siblings().first());
      }
      old.$.effect("highlight", { easing: 'easeInExpo' }, 4000);
    });
  }
  
});
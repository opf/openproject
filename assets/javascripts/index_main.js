// Initialize the backlogs after DOM is loaded
$(function() {
  // Initialize each backlog
  $('.backlog').each(function(index){
    backlog = RB.Factory.initialize(RB.Backlog, this); // 'this' refers to an element with class="backlog"
  });
  
  $('#refresh').bind('click', RB.indexMain.handleRefreshClick);
  RB.pollWait = 1000;
  RB.indexMain.pollForUpdates()
});

RB.indexMain = RB.Object.create({
  
  handleRefreshClick: function(event, ui){
    RB.pollWait = 1000;
    RB.indexMain.loadData();
  },
  
  loadData: function(){
    $('body').addClass('loading');
    $.ajax({
      type: "GET",
      url: RB.urlFor['list_stories'],
      data: { after     : $('#last_updated').text(),
              project_id: RB.constants.project_id
            },
      complete: RB.indexMain.refresh
    });
  },
  
  pollForUpdates: function() {
    setTimeout(
      function() {
        RB.indexMain.loadData();
      }, 
      RB.pollWait
    );
  },
  
  refresh: function(xhr, statusText){
    $('body').removeClass('loading');
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
        var backlog = updated.$.find(".sprint").text().length==0 ? $('#product_backlog') : $('#sprint_' + updated.$.find(".sprint").text());
        backlog.find('.stories').first().prepend(old.$);
      }
      old.$.effect("highlight", { easing: 'easeInExpo' }, 4000);
    });
    
    if(stories.length==0 && RB.pollWait < 60000){
      RB.pollWait += 250;
    } else {
      RB.pollWait = 1000;
    }
    RB.indexMain.pollForUpdates();
  }
  
});
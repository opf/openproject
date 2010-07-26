// Initialize the backlogs after DOM is loaded
$(function() {
  // Initialize each backlog
  $('.backlog').each(function(index){
    backlog = RB.Factory.initialize(RB.Backlog, this); // 'this' refers to an element with class="backlog"
  });
  
  $('#refresh').bind('click', RB.indexMain.handleRefreshClick);
  $('#disable_autorefresh').bind('click', RB.indexMain.handleDisableAutorefreshClick);

  RB.pollWait = 1000;
  RB.indexMain.pollForUpdates()
});

RB.indexMain = RB.Object.create({
  
  handleDisableAutorefreshClick: function(event, ui){
    $('body').toggleClass('no_autorefresh');
    if($('body').hasClass('no_autorefresh')){
      $('#disable_autorefresh').text('Enable Auto-refresh');
    } else {
      RB.pollWait = 1000;
      RB.indexMain.pollForUpdates();
      $('#disable_autorefresh').text('Disable Auto-refresh');
    }
  },

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
    if($('body').hasClass('no_autorefresh')) return false;

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

      var story;
      if($('#story_' + updated.getID()).length==0){
        story = updated;
      } else {
        console.log('#story_' + updated.getID());
        story = $('#story_' + updated.getID()).data('this');
        story.$.html(updated.$.html());
      }

      var editing = story.$.hasClass('editing');
      
      if(previous.length > 0){
        story.$.insertAfter($("#story_" + previous));
      } else {
        var backlog = updated.$.find(".sprint").text().length==0 ? $('#product_backlog') : $('#sprint_' + updated.$.find(".sprint").text());
        backlog.find('.stories').first().prepend(story.$);
      }
      if(updated.$.hasClass('closed')){
        story.$.addClass('closed');
      } else {
        story.$.removeClass('closed');
      }
      story.refresh();
      if(editing) story.edit();
      if(story.$.data('focus')!=null && story.$.data('focus').length>0) story.$.find("*[name=" + story.$.data('focus') + "]").focus();
      story.$.effect("highlight", { easing: 'easeInExpo' }, 4000);
    });
    
    if(stories.length==0 && RB.pollWait < 60000 && !$('body').hasClass('no_autorefresh')){
      RB.pollWait += 250;
    } else {
      RB.pollWait = 1000;
    }
    RB.indexMain.pollForUpdates();
  }
  
});
RB.BacklogsUpdater = RB.Object.create(RB.BoardUpdater, {

  processItem: function(html){
    var update = RB.Factory.initialize(RB.Story, html);
    var target;
    
    if($('#story_' + update.getID()).length==0){
      target = update;                                      // Create a new item
    } else {
      target = $('#story_' + update.getID()).data('this');  // Re-use existing item
      target.refresh(update);
    }

    var oldParent = target.getParent();

    // Position the story properly in the backlog
    var previous = update.$.find(".previous").text();
    if(previous.length > 0){
      target.$.insertAfter( $('#story_' + previous) );
    } else {
      var backlog = target.$.find(".sprint").text().length==0 ? $('#product_backlog') : $('#sprint_' + target.$.find(".sprint").text());
      backlog.find('.stories').first().prepend(target.$);
    }

    if(oldParent!=null) oldParent.recalcPoints();
    target.getParent().recalcPoints();

    // Retain edit mode and focus if user was editing the
    // story before an update was received from the server    
    if(target.$.hasClass('editing')) target.edit();
    if(target.$.data('focus')!=null && target.$.data('focus').length>0) target.$.find("*[name=" + target.$.data('focus') + "]").focus();
        
    target.$.effect("highlight", { easing: 'easeInExpo' }, 4000);
  },

  
  start: function(){
    this.itemType   = 'story';
    this.urlFor     = 'list_stories';
    this.params     = '';
    this.objectType = RB.Story;
    
    this.initialize();
  }

});
RB.BacklogsUpdater = RB.Object.create(RB.BoardUpdater, {
  processAllItems: function(data){
    var self = this;

    // Process all stories
    var items = $(data).find('#stories .story');
    items.each(function(i, v){
      self.processItem(v, false);
    });
  },

  processItem: function(html){
    var update = RB.Factory.initialize(RB.Story, html);
    var target;
    var oldParent;
    
    if($('#story_' + update.getID()).length==0){
      target = update;                                      // Create a new item
    } else {
      target = $('#story_' + update.getID()).data('this');  // Re-use existing item
      oldParent = $('#story_' + update.getID()).parents(".backlog").first().data('this');
      target.refresh(update);
    }

    // Position the story properly in the backlog
    var previous = update.$.find(".higher_item_id").text();
    if(previous.length > 0){
      target.$.insertAfter( $('#story_' + previous) );
    } else {
      if(target.$.find(".fixed_version_id").text().length==0){
        // Story belongs to the product backlog
        var stories = $('#product_backlog_container .backlog .stories');
      } else {
        // Story belongs to a sprint backlog
        var stories = $('#sprint_' + target.$.find(".fixed_version_id").text()).siblings(".stories").first();
      }
      stories.prepend(target.$);
    }

    if(oldParent!=null) oldParent.recalcVelocity();
    target.$.parents(".backlog").first().data('this').recalcVelocity();

    // Retain edit mode and focus if user was editing the
    // story before an update was received from the server    
    if(target.$.hasClass('editing')) target.edit();
    if(target.$.data('focus')!=null && target.$.data('focus').length>0) target.$.find("*[name=" + target.$.data('focus') + "]").focus();
        
    target.$.effect("highlight", { easing: 'easeInExpo' }, 4000);
  },

  start: function(){
    this.params     = 'only=stories';
    this.initialize();
  }

});
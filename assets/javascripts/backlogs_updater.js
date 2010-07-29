RB.BacklogsUpdater = RB.Object.create(RB.BoardUpdater, {
  
  processItem: function(obj, update){
    var target = obj;
    var editing = target.$.hasClass('editing');
    var previous = target.$.find(".previous").text();
    
    // Position the task properly in the taskboard
    if(previous.length > 0){
      target.$.insertAfter( $('#' + this.itemType + '_' + previous) );
    } else {
      var backlog = target.$.find(".sprint").text().length==0 ? $('#product_backlog') : $('#sprint_' + target.$.find(".sprint").text());
      backlog.find('.stories').first().prepend(target.$);
    }

    if(update!=null && update.$.hasClass('closed')){
      story.$.addClass('closed');
    } else if (update!=null) {
      story.$.removeClass('closed');
    }
    
    target.refresh();
    if(editing) target.edit();
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
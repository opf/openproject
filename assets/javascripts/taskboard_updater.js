RB.TaskboardUpdater = RB.Object.create(RB.BoardUpdater, {

  processAllItems: function(data){
    var self = this;
    
    // Process tasks
    var items = $(data).children('.task');
    items.each(function(i, v){
      self.processItem(v, false);
    });
  },
  
  processItem: function(html, isImpediment){
    var update = RB.Factory.initialize(isImpediment ? RB.Impediment : RB.Task, html);
    var target;
    var idPrefix = '#' + (isImpediment ? 'impediment' : 'task') + '_';
    
    if($(idPrefix + update.getID()).length==0){
      target = update;                                     // Create a new item
    } else {
      target = $(idPrefix + update.getID()).data('this');  // Re-use existing item
      target.refresh(update);
    }

    // Position the item properly in the taskboard
    var cell, previous, items;
    if(isImpediment){
      throw "Locator for impediment not yet defined";
    } else {
      cell = $('#' + target.$.find('.meta .story_id').text() + '_' + target.$.find('.meta .status_id').text());
      cell.prepend(target.$);
    }
    
    // sort items in the cell according to position
    items = cell.children('.task').get();
    items.sort( function(a, b) { return parseInt($(a).find('.position').text()) > parseInt($(b).find('.position').text()) });
    console.log(items);
    for(var ii=0; ii<items.length; ii++){
      cell.append(items[ii]);
    }

    // Retain edit mode and focus if user was editing the
    // task before an update was received from the server    
    // if(target.$.hasClass('editing')) target.edit();
    // if(target.$.data('focus')!=null && target.$.data('focus').length>0) target.$.find("*[name=" + target.$.data('focus') + "]").focus();
        
    target.$.effect("highlight", { easing: 'easeInExpo' }, 4000);
  },
  
  start: function(){
    this.urlFor     = 'list_tasks';
    this.params     = 'sprint_id=' + RB.constants.sprint_id + '&include_impediments=true';  // RB.constants is defined in backlogs/jsvariables.js.erb
    
    this.initialize();
  }

});
RB.TaskboardUpdater = RB.Object.create(RB.BoardUpdater, {

  processAllItems: function(data){
    var self = this;
    
    // Process tasks
    var items = $(data).children('.task');
    items.each(function(i, v){
      self.processItem(v, false);
    });

    // Process impediments
    var items = $(data).children('.impediment');
    items.each(function(i, v){
      self.processItem(v, true);
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

    // Place the item in the correct cell
    var cell, previous, items;
    cell = isImpediment ? $('#impcell_' + target.$.find('.meta .status_id').text()) : $('#' + target.$.find('.meta .story_id').text() + '_' + target.$.find('.meta .status_id').text());
    cell.prepend(target.$);

    // Sort items in the cell
    items = cell.children('.task').get();
    items.sort( function(a, b) { 
      a = isNaN($(a).find('.prev').text()) ? 0 : parseInt($(a).find('.prev').text());
      b = isNaN($(b).find('.prev').text()) ? 0 : parseInt($(b).find('.prev').text());
      return a > b;
    });
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
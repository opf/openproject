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
    var idPrefix = '#issue_';
    
    if($(idPrefix + update.getID()).length==0){
      target = update;                                     // Create a new item
    } else {
      target = $(idPrefix + update.getID()).data('this');  // Re-use existing item
      target.refresh(update);
    }

    var cell, previous;

    // Find the correct cell for the item
    cell = isImpediment ? $('#impcell_' + target.$.find('.meta .status_id').text()) : $('#' + target.$.find('.meta .story_id').text() + '_' + target.$.find('.meta .status_id').text());

    // Check if the item's predecessor is in the same cell
    // because we have a unified list for all issues in the db
    previous = cell.find(idPrefix + target.$.find('.meta .previous').text());

    if(previous.length>0){
      target.$.insertAfter(previous);   // Insert after predecessor
    } else {
      cell.prepend(target.$);           // Insert as first item of the cell
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
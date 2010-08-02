RB.TaskboardUpdater = RB.Object.create(RB.BoardUpdater, {
  
  processItem: function(html){
    var update = RB.Factory.initialize(RB.Task, html);
    var target;
    
    if($('#task_' + update.getID()).length==0){
      target = update;                                     // Create a new item
    } else {
      target = $('#task_' + update.getID()).data('this');  // Re-use existing item
      target.refresh(update);
    }

    // Position the task properly in the taskboard
    var previous = update.$.find(".previous").text();
    if(previous.length > 0){
      target.$.insertAfter( $('#task_' + previous) );
    } else {
      $('#' + target.$.find('.meta .story_id').text() + '_' + target.$.find('.meta .status_id').text()).prepend(target.$);
    }

    // Retain edit mode and focus if user was editing the
    // task before an update was received from the server    
    if(target.$.hasClass('editing')) target.edit();
    if(target.$.data('focus')!=null && target.$.data('focus').length>0) target.$.find("*[name=" + target.$.data('focus') + "]").focus();
        
    target.$.effect("highlight", { easing: 'easeInExpo' }, 4000);
  },
  
  start: function(){
    this.itemType   = 'task';
    this.urlFor     = 'list_tasks';
    this.params     = 'sprint_id=' + RB.constants.sprint_id;  // RB.constants is defined in backlogs/jsvariables.js.erb
    this.objectType = RB.Task;
    
    this.initialize();
  }

});
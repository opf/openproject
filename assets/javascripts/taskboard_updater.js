RB.TaskboardUpdater = RB.Object.create(RB.BoardUpdater, {
  
  processItem: function(obj){
    var target = obj;
    var editing = target.$.hasClass('editing');
    var previous = target.$.find(".previous").text();
    
    // Position the task properly in the taskboard
    if(previous.length > 0){
      target.$.insertAfter( $('#' + this.itemType + '_' + previous) );
    } else {
      $('#' + target.$.find('.meta .story_id').text() + '_' + target.$.find('.meta .status_id').text()).prepend(target.$);
    }
    
    target.refresh();
    if(editing) target.edit();
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
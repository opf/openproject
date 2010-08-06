/***************************************
  TASKBOARD
***************************************/

RB.Taskboard = RB.Object.create(RB.Model, {
    
  initialize: function(el){
    var j = $(el);
    var self = this; // So we can bind the event handlers to this object
    
    self.$ = j;
    self.el = el;
    
    // Associate this object with the element for later retrieval
    j.data('this', self);

    // Initialize column widths
    self.colWidthUnit = $(".swimlane").width();
    self.defaultColWidth = 2;
    self.loadColWidthPreference();
    self.updateColWidths();
    $("#col_width input").bind('keyup', function(e){ if(e.which==13) self.updateColWidths() });

    // Initialize tasks
    j.find("#tasks .list").sortable({ 
      connectWith: '#tasks .list', 
      placeholder: 'placeholder',
      start: self.dragStart,
      stop: self.dragStop,
      update: self.dragComplete
    });

    // Initialize each task in the board
    j.find('.task').each(function(index){
      var task = RB.Factory.initialize(RB.Task, this); // 'this' refers to an element with class="task"
    });

    // Add handler for .add_new click
    j.find('#tasks .add_new').bind('mouseup', self.handleAddNewTaskClick);
  },
  
  dragComplete: function(event, ui) {
    var isDropTarget = (ui.sender==null); // Handler is triggered for source and target. Thus the need to check.

    if(isDropTarget){
      ui.item.data('this').saveDragResult();
    }    
  },
  
  dragStart: function(event, ui){ 
    ui.item.addClass("dragging");
  },
  
  dragStop: function(event, ui){ 
    ui.item.removeClass("dragging");  
  },
  
  handleAddNewTaskClick: function(event){
    var row = $(this).parents("tr").first();
    $('#taskboard').data('this').newTask(row);
  },

  loadColWidthPreference: function(){
    var w = RB.UserPreferences.get('taskboardColWidth');
    if(w==null){
      w = this.defaultColWidth;
      RB.UserPreferences.set('taskboardColWidth', w);
    }
    $("#col_width input").val(w);
  },
        
  newTask: function(row){
    var task = $('#task_template').children().first().clone();
    row.find(".list").first().prepend(task);
    o = RB.Factory.initialize(RB.Task, task[0]);
    // o.edit();
    // task.find('.editor' ).first().focus();
  },
  
  updateColWidths: function(){
    var w = parseInt($("#col_width input").val());
    if(w==null || isNaN(w)){
      w = this.defaultColWidth;
    }
    $("#col_width input").val(w)
    RB.UserPreferences.set('taskboardColWidth', w);
    $(".swimlane").width(this.colWidthUnit * w).css('min-width', this.colWidthUnit * w);
  }
});

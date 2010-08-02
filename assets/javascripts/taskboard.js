/***************************************
  TASKBOARD
***************************************/

RB.Taskboard = RB.Object.create(RB.Model, {
    
  initialize: function(el){
    var j;  // This ensures that we use a local 'j' variable, not a global one.
    var self = this;
    
    this.$ = j = $(el);
    this.el = el;
    
    // Associate this object with the element for later retrieval
    j.data('this', this);

    // Set column widths
    this.colWidthUnit = $("#taskboard .list").width();
    this.defaultColWidth = 2;
    this.loadColWidthPreference();
    this.updateColWidths();
    $("#col_width input").bind('keyup', function(e){ if(e.which==13) self.updateColWidths() });

    // Initialize all lists
    $(".list").sortable({ 
      connectWith: '.list', 
      placeholder: 'placeholder',
      start: this.dragStart,
      stop: this.dragStop,
      update: this.dragComplete
    });

    // Initialize each task in the board
    $('.task').each(function(index){
      task = RB.Factory.initialize(RB.Task, this); // 'this' refers to an element with class="task"
    });
    
    // Add handler for new_task_button click
    j.find('.new_task_button').bind('mouseup', this.handleNewTaskButtonClick);
    
    $('.show_charts').bind('click', function(ev){ self.showCharts(ev) }); // capture 'click' instead of 'mouseup' so we can preventDefault();
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
  
  getFirstcolumnList: function(row){
  },
  
  handleNewTaskButtonClick: function(event){
    var button = $(this);
    $('#taskboard').data('this').newTask(button.next());
  },

  loadColWidthPreference: function(){
    var w = RB.UserPreferences.get('taskboardColWidth');
    if(w==null){
      w = this.defaultColWidth;
      RB.UserPreferences.set('taskboardColWidth', w);
    }
    $("#col_width input").val(w);
  },
      
  loadTaskTemplate: function(){
    $.ajax({
        type: "GET",
        async: false,
        url: RB.urlFor['new_task'],
        complete: function(xhr, textStatus){ $(xhr.responseText).removeClass("task").appendTo("#content").wrap("<div id='task_template'/>") } // removeClass() ensures that $(".story") will not include this node
    });
  },
    
  newTask: function(target){
    if($('#task_template').size()==0){
      this.loadTaskTemplate();
    }

    var task = $('#task_template').children().first().clone();
    target.prepend(task);
    o = RB.Factory.initialize(RB.Task, task[0]); // 'this' refers to an element with class="task"
    o.edit();
    
    task.find('.editor' ).first().focus();
  },

  showCharts: function(event){
    event.preventDefault();
    $('#charts').html("<div class='loading'>Loading data...</div>");
    $('#charts').load(RB.urlFor['show_charts'] + '?project_id=' + RB.constants['project_id'] + '&sprint_id=' + RB.constants.sprint_id);
    $('#charts').dialog({ 
                          buttons: { "Close": function() { $(this).dialog("close") } },
                          height: 790,
                          modal: true, 
                          title: 'Charts', 
                          width: 710 
                       });
  },
  
  updateColWidths: function(){
    var w = parseInt($("#col_width input").val());
    if(w==null || isNaN(w)){
      w = this.defaultColWidth;
    }
    $("#col_width input").val(w)
    RB.UserPreferences.set('taskboardColWidth', w);
    $("#taskboard .list").width(this.colWidthUnit * w).css('min-width', this.colWidthUnit * w);
  }
});

/***************************************
  TASKBOARD
***************************************/

RB.Taskboard = RB.Object.create(RB.Model, {
    
  initialize: function(el){
    var j;  // This ensures that we use a local 'j' variable, not a global one.
    
    this.$ = j = $(el);
    this.el = el;
    
    // Associate this object with the element for later retrieval
    j.data('this', this);

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
  },
  
  dragComplete: function(event, ui) {
    var isDropTarget = (ui.sender==null); // Handler is triggered for source and target. Thus the need to check.

    if(isDropTarget){
      var cellID = $(ui.item).parent('td').first().attr('id').split("_");

      var data = {
        id: ui.item.data('this').getID(),
        parent_issue_id: cellID[0],
        status_id: cellID[1]
      }

      $.ajax({
          type: "POST",
          url: RB.urlFor['update_task'],
          data: data,
          beforeSend: function(xhr){ ui.item.data('this').markSaving() },
          complete: function(xhr, textStatus){ ui.item.data('this').unmarkSaving() }
      });
    }    
  },
  
  dragStart: function(event, ui){ 
    ui.item.addClass("dragging");
  },
  
  dragStop: function(event, ui){ 
    ui.item.removeClass("dragging");  
  },
      
  newTask: function(){
  }
});
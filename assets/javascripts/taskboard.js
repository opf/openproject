/***************************************
  TASKBOARD
***************************************/

RB.Taskboard = Object.create(RB.Model, {
    
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
      stop: this.dragStop
    });

    // Initialize each task in the board
    $('.task').each(function(index){
      task = RB.Factory.initialize(RB.Task, this); // 'this' refers to an element with class="task"
    });
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
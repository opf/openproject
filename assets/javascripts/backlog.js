/***************************************
  BACKLOG
***************************************/

RB.Backlog = Object.create(RB.Model, {
    
  initialize: function(el){
    this.$ = j = $(el);
    this.el = el;
    
    // Associate this object with the element for later retrieval
    j.data('this', this);
    
    // Make the list sortable
    list = this.getList();
    list.sortable({ connectWith: '.stories',
                    placeholder: 'placeholder',
                    forcePlaceholderSize: true,
                    dropOnEmpty: true,
                    start: this.dragStart,
                    stop: this.dragStop,
                    update: this.dragComplete
                    });
    list.disableSelection();
    
    // Initialize each item in the backlog
    this.getStories().each(function(index){
      story = RB.Factory.initialize(RB.Story, this); // 'this' refers to an element with class="story"
    });
  },
  
  dragComplete: function(event, ui) {
    me = $(this).parent('.backlog').data('this'); // Because 'this' represents the sortable ul element
    
    if(me.isSprint()) me.recalcPoints();

    stories = $(event.target).sortable('serialize');    
    dropped = '&dropped=' + ui.item.data('this').getID();
    
    if(ui.sender){
      moveto = '&moveto=' + $(event.target).parent('.backlog').data('this').getID();
    } else {
      moveto = '';
    }

    $.ajax({
        type: "POST",
        url: RB.urlFor['reorder'],
        data: stories + moveto + dropped,
    });
  },
  
  dragStart: function(event, ui){ 
    ui.item.addClass("dragging");
  },
  
  dragStop: function(event, ui){ 
    ui.item.removeClass("dragging");  
  },
  
  getID: function(){
    return this.isSprint() ? this.$.attr('id').split('_')[1] : this.$.attr('id');
  },
  
  getStories: function(){
    return this.getList().children(".story");
  },

  getList: function(){
    return $(this.el).children(".stories").first();
  },
  
  isSprint: function(){
    return $(this.el).hasClass('sprint');
  },
  
  recalcPoints: function(){
    total = 0;
    this.getStories().each(function(index){
      total += $(this).data('this').getPoints();
    });
    this.$.children('.header').children('.points').text(total);
  }
  
});
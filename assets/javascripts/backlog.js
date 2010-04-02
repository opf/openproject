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
                    start: function(event, ui){ ui.item.addClass("dragging")     },
                    stop : function(event, ui){ ui.item.removeClass("dragging")  } 
                    });
    list.disableSelection();
    
    // Initialize each item in the backlog
    this.getStories().each(function(index){
      story = RB.Factory.initialize(RB.Story, this); // 'this' refers to an element with class="story"
    });
  },
  
  getStories: function(){
    return this.getList().children(".story");
  },

  getList: function(){
    return $(this.el).children(".stories").first();
  }
  
});
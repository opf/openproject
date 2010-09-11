/******************************************
  BACKLOG
  A backlog is a visual representation of
  a sprint and its stories. It's is not a
  sprint. Imagine it this way: a sprint is
  a start and end date, and a set of 
  objectives. A backlog is something you
  would draw up on the board or a spread-
  sheet (or in Redmine Backlogs!) to 
  visualize the sprint.
******************************************/

RB.Backlog = RB.Object.create({
    
  initialize: function(el){
    var j;  // This ensures that we use a local 'j' variable, not a global one.
    var self = this;
    
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
                    update: function(e,u){ self.dragComplete(e, u) }
                    });

    // Observe menu items
    j.find('.new_story').bind('mouseup', this.handleMenuClick);
    j.find('.show_burndown_chart').bind('click', function(ev){ self.showBurndownChart(ev) }); // capture 'click' instead of 'mouseup' so we can preventDefault();

    if(this.isSprintBacklog()){
      sprint = RB.Factory.initialize(RB.Sprint, this.getSprint());
    }

    // Initialize each item in the backlog
    this.getStories().each(function(index){
      story = RB.Factory.initialize(RB.Story, this); // 'this' refers to an element with class="story"
    });
    
    if (this.isSprintBacklog()) this.recalcVelocity();
    
    // Handle New Story clicks
    j.find('.add_new_story').bind('mouseup', self.handleNewStoryClick);
  },
  
  dragComplete: function(event, ui) {
    var isDropTarget = (ui.sender==null);

    // jQuery triggers dragComplete of source and target. 
    // Thus we have to check here. Otherwise, the story
    // would be saved twice.
    if(isDropTarget){
      ui.item.data('this').saveDragResult();
    }

    this.recalcVelocity();
  },
  
  dragStart: function(event, ui){ 
    ui.item.addClass("dragging");
  },
  
  dragStop: function(event, ui){ 
    ui.item.removeClass("dragging");  
  },
  
  getSprint: function(){
    return $(this.el).children(".sprint").first();
  },
    
  getStories: function(){
    return this.getList().children(".story");
  },

  getList: function(){
    return this.$.children(".stories").first();
  },

  handleNewStoryClick: function(event){
    event.preventDefault();
    $(this).parents('.backlog').data('this').newStory();
  },

  isSprintBacklog: function(){
    return $(this.el).children('.sprint').length == 1; // return true if backlog has an element with class="sprint"
  },
    
  newStory: function(){
    var story = $('#story_template').children().first().clone();
    
    this.getList().prepend(story);
    o = RB.Factory.initialize(RB.Story, story[0]);
    o.edit();
    story.find('.editor' ).first().focus();
  },
  
  recalcVelocity: function(){
    if( !this.isSprintBacklog() ) return true;
    total = 0;
    this.getStories().each(function(index){
      total += $(this).data('this').getPoints();
    });
    this.$.children('.header').children('.velocity').text(total);
  },

  showBurndownChart: function(event){
    event.preventDefault();
    if($("#charts").length==0){
      $( document.createElement("div") ).attr('id', "charts").appendTo("body");
    }
    $('#charts').html( "<div class='loading'>Loading data...</div>");
    $('#charts').load( RB.urlFor('show_burndown_chart', { id: this.getSprint().data('this').getID() }) );
    $('#charts').dialog({ 
                          buttons: { "Close": function() { $(this).dialog("close") } },
                          height: 790,
                          modal: true, 
                          title: 'Charts', 
                          width: 710 
                       });
  }
});
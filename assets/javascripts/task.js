/**************************************
  TASK
***************************************/

RB.Task = RB.Object.create(RB.Story, {
  
  initialize: function(el){
    var j;  // This ensures that we use a local 'j' variable, not a global one.
    
    this.$ = j = $(el);
    this.el = el;
    
    j.addClass("task"); // If node is based on #task_template, it doesn't have the story class yet

    // Associate this object with the element for later retrieval
    j.data('this', this);

    // Observe click events in certain fields
    j.find('.editable').bind('mouseup', this.triggerEdit);
  },

  checkSubjectLength: function(){
  },
  
  handleKeyup: function(event){
    var j = $(this).parents('.task').first();
    var that = j.data('this');

    switch(event.which){
      case 13   : that.saveEdits();   // Enter
                  break;
      case 27   : that.cancelEdit();     // ESC
                  break;
      default   : return true;
    }
  },

  markSaving: function(){
    this.$.addClass('saving');
  },

  // Override saveDirectives of RB.Story
  saveDirectives: function(){
    var j = this.$;
    var cellID = j.parent('td').first().attr('id').split("_");

    var data = j.find('.editor').serialize() +
               "&parent_issue_id=" + cellID[0] +
               (this.isNew() ? "" : "&id=" + j.children('.id').text());
    var url = RB.urlFor[(this.isNew() ? 'create_task' : 'update_task')];
    
    return {
      url: url,
      data: data
    }
  },

  triggerEdit: function(event){
    // Get the task since what was clicked was a field
    var j = $(this).parents('.task').first();
    
    if(!j.hasClass('editing') && !j.hasClass('dragging')){
      j.data('this').edit();
      
      // Focus on the input corresponding to the field clicked
      j.find( '.' + $(event.currentTarget).attr('fieldname') + '.editor' ).focus();
    }
  },

  unmarkSaving: function(){
    this.$.removeClass('saving');
  }  
  
});

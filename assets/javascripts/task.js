/**************************************
  TASK
***************************************/

RB.Task = RB.Object.create(RB.Issue, {
  
  initialize: function(el){
    var j;  // This ensures that we use a local 'j' variable, not a global one.
    
    this.$ = j = $(el);
    this.el = el;
    
    j.addClass("task"); // If node is based on #task_template, it doesn't have the story class yet
    
    // Associate this object with the element for later retrieval
    j.data('this', this);
    
    j.find(".editable").live('mouseup', this.handleClick);
  },

  beforeSave: function(){
    var c = this.$.find('select.assigned_to_id').children(':selected').attr('color');
    this.$.css('background-color', c);
  },
  
  editorDisplayed: function(dialog){
    dialog.parents('.ui-dialog').css('background-color', this.$.css('background-color'));
  },

  getType: function(){
    return "Task";
  },

  markIfClosed: function(){
    if(this.$.parent('td').first().hasClass('closed')){
      this.$.addClass('closed');
    } else {
      this.$.removeClass('closed');
    }
  },

  saveDirectives: function(){
    var j = this.$;
    var prev = this.$.prev();
    var cellID = j.parent('td').first().attr('id').split("_");

    var data = j.find('.editor').serialize() +
               "&parent_issue_id=" + cellID[0] +
               "&status_id=" + cellID[1] +
               "&prev=" + (prev.length==1 ? prev.data('this').getID() : '') +
               (this.isNew() ? "" : "&id=" + j.children('.id').text());

    if( this.isNew() ){
      var url = RB.urlFor( 'create_task' );
    } else {
      var url = RB.urlFor( 'update_task', { id: this.getID() } );
      data += "&_method=put"
    }
    
    return {
      url: url,
      data: data
    }
  },

  beforeSaveDragResult: function(){
    if(this.$.parent('td').first().hasClass('closed')){
      // This is only for the purpose of making the Remaining Hours reset
      // instantaneously after dragging to a closed status. The server should
      // still make sure to reset the value to be sure.
      this.$.children('.remaining_hours.editor').val('');
      this.$.children('.remaining_hours.editable').text('');
    }
  }
  
});

/**************************************
  STORY
***************************************/
RB.Story = RB.Object.create(RB.Issue, RB.EditableInplace, {
  initialize: function(el){
    var j;  // This ensures that we use a local 'j' variable, not a global one.
    var self = this;
    
    this.$ = j = $(el);
    this.el = el;
    
    // Associate this object with the element for later retrieval
    j.data('this', this);

    j.find(".editable").live('mouseup', this.handleClick);
  },

  beforeSave: function(){
    // Do nothing
  },
  
  editDialogTitle: function(){
    return "Story #" + this.getID();
  },

  editorDisplayed: function(editor){
    // editor.dialog("option", "position", "center");
  },
  
  getPoints: function(){
    points = parseInt( this.$.find('.story_points').first().text() );
    return ( isNaN(points) ? 0 : points );
  },

  getType: function(){
    return "Story";
  },

  markIfClosed: function(){
    // Do nothing
  },
  
  newDialogTitle: function(){
    return "New Story";
  },

  saveDirectives: function(){
    var j = this.$;
    var prev = this.$.prev();
    var sprint_id = this.$.parents('.backlog').data('this').isSprintBacklog() ? 
                    this.$.parents('.backlog').data('this').getSprint().data('this').getID() : '';
        
    var data = "prev=" + (prev.length==1 ? this.$.prev().data('this').getID() : '') +
               "&fixed_version_id=" + sprint_id;
    
    if(j.find('.editor').length > 0) data += "&" + j.find('.editor').serialize();
    
    if( this.isNew() ){
      var url = RB.urlFor( 'create_story' );
    } else {
      var url = RB.urlFor( 'update_story', { id: this.getID() } );
      data += "&_method=put"
    }
    
    return {
      url: url,
      data: data
    }
  },

  beforeSaveDragResult: function(){
    // Do nothing
  }
});
  
/***************************************
  SPRINT
***************************************/

RB.Sprint = RB.Object.create(RB.Model, RB.EditableInplace, {

  initialize: function(el){
    var j;  // This ensures that we use a local 'j' variable, not a global one.
    var self = this;
    
    this.$ = j = $(el);
    this.el = el;
    
    // Associate this object with the element for later retrieval
    j.data('this', this);

    j.find(".editable").bind('mouseup', this.handleClick);
  },

  beforeSave: function(){
    // Do nothing
  },

  getType: function(){
    return "Sprint";
  },

  markIfClosed: function(){
    // Do nothing
  },
  
  refreshed: function(){
    // We have to do this since .live() does not work for some reason
    j.find(".editable").bind('mouseup', this.handleClick);
  },

  saveDirectives: function(){
    var j = this.$;

    var data = j.find('.editor').serialize() + "&_method=put";
    var url = RB.urlFor('update_sprint', { id: this.getID() });
    
    return {
      url : url,
      data: data
    }
  },

  beforeSaveDragResult: function(){
    // Do nothing
  }
  
});
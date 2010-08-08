/**************************************
  IMPEDIMENT
***************************************/

RB.Impediment = RB.Object.create(RB.Task, {
  
  initialize: function(el){
    var j;  // This ensures that we use a local 'j' variable, not a global one.
    
    this.$ = j = $(el);
    this.el = el;
    
    j.addClass("impediment"); // If node is based on #task_template, it doesn't have the impediment class yet
    
    // Associate this object with the element for later retrieval
    j.data('this', this);
    
    j.bind('mouseup', this.handleClick);
  },
  
  // Override saveDirectives of RB.Task
  saveDirectives: function(){
    var j = this.$;
    var prev = this.$.prev();
    var statusID = j.parent('td').first().attr('id').split("_")[1];
      
    var data = j.find('.editor').serialize() +
               "&is_impediment=true" +
               "&fixed_version_id=" + RB.constants['sprint_id'] +
               "&status_id=" + statusID +
               "&prev=" + (prev.length==1 ? prev.data('this').getID() : '') +
               (this.isNew() ? "" : "&id=" + j.children('.id').text());
    var url = RB.urlFor[(this.isNew() ? 'create_task' : 'update_task')];
    
    return {
      url: url,
      data: data
    }
  },
  
  // Override RB.Story.storyUpdated()
  storyUpdated: function(xhr, textStatus){
    var me = $('#impediment_' + RB.Factory.initialize(RB.Story, xhr.responseText).getID()).data('this');
  
    me.unmarkSaving();
    if(xhr.status!=200){
      me.markError();
    } else {
      me.unmarkError();
    }
  }

});

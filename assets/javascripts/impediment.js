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
    
    j.find(".editable").live('mouseup', this.handleClick);
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

    if( this.isNew() ){
      var url = RB.urlFor('create_impediment');
    } else {
      var url = RB.urlFor('update_impediment', { id: this.getID() });
      data += "&_method=put"
    }
        
    return {
      url: url,
      data: data
    }
  }

});

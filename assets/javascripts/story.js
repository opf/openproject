/**************************************
  STORY
***************************************/
RB.Story = Object.create(RB.Model, {
  
  initialize: function(el){
    var j;  // This ensures that we use a local 'j' variable, not a global one.
    
    this.$ = j = $(el);
    this.el = el;
    
    // Associate this object with the element for later retrieval
    j.data('this', this);

    // Observe click events in certain fields
    j.find('.editable').bind('mouseup', this.triggerEdit);
    
    this.checkSubjectLength();
  },

  cancelEdit: function(){
    this.$.removeClass('editing');
    this.checkSubjectLength();
    if(this.isNew()){
      this.$.hide('blind');
    }
  },

  checkSubjectLength: function(){
    if(this.$.find('div.subject').text().length>=60){
      this.$.addClass('subject_over_sixty');
      $("<div class='elipses'>...</div>").appendTo(this.$);
    }else{
      this.$.removeClass('subject_over_sixty');
    }
  },

  edit: function(){
    j = this.$;
      
    j.addClass('editing');
    
    j.find('.editable').each(function(index){
      field = $(this);
      fieldType = field.attr('fieldtype')!=null ? field.attr('fieldtype') : 'input';
      fieldName = field.attr('fieldname');
      input = j.find(fieldType + '.' + fieldName);
      
      // Create the input element for the field if it does not yet exist
      if(input.size()==0){
        input = fieldType=='select' ? $('#' + fieldName + '_options').clone(true) : $(document.createElement(fieldType));
        input.removeAttr('id');
        input.attr('name', fieldName);
        input.addClass(fieldName);
        input.addClass('editor');
        input.appendTo(j);
        input.bind('keyup', j.data('this').handleKeyup);
      } else {
        input = input.first();
      }
      
      // Copy the value in the field to the input element
      value = ( fieldType=='select' ? field.children('.v').first().text() : field.text() );
      input.val(value);
    });
  },
  
  endEdit: function(){
    this.$.removeClass('editing');
    this.checkSubjectLength();
  },
  
  getID: function(){
    return this.$.children('.id').text();
  },
  
  getPoints: function(){
    points = parseInt(this.$.children('.story_points').text());
    return ( isNaN(points) ? 0 : points );
  },
  
  handleKeyup: function(event){
    j = $(this).parents('.story').first();
    that = j.data('this');

    switch(event.which){
      case 13   : that.saveEdits();   // Enter
                  break;
      case 27   : that.cancelEdit();     // ESC
                  break;
      default   : return true;
    }
  },
  
  isNew: function(){
    return this.$.children('.id').text()=="";
  },
  
  markSaving: function(){
    this.$.addClass('saving');
  },
  
  saveEdits: function(){
    j = this.$;
    me = j.data('this');
    editors = j.find('.editor');
    
    editors.each(function(index){
      editor = $(this);
      fieldName = editor.attr('name');
      if(this.type.match(/select/)){
        j.children('div.' + fieldName).children('.v').text(editor.val())
        j.children('div.' + fieldName).children('.t').text(editor.children(':selected').text());
      } else if(this.type.match(/textarea/)){
      //   this.setValue('div.' + fieldName + ' .textile', editors[ii].value);
      //   this.setValue('div.' + fieldName + ' .html', '-- will be displayed after save --');
      } else {
        j.children('div.' + fieldName).text(editor.val());
      }
    });

    if(j.children("select.status_id").children(":selected").hasClass('closed')){
      j.addClass('closed');
    } else {
      j.removeClass('closed');
    }

    $.ajax({
      type: "POST",
      url: RB.urlFor[(me.isNew() ? 'create_story' : 'update_story')],
      data: editors.serialize() + (me.isNew() ? "" : "&id=" + j.children('.id').text()),
      beforeSend: function(xhr){ me.markSaving() },
      complete: (me.isNew() ? this.storyCreated : this.storyUpdated) 
    });
    me.endEdit();
    
    var sprint = j.parents('.sprint.backlog');
    if(sprint.size()>0) sprint.data('this').recalcPoints();
  },
  
  storyCreated: function(xhr, textStatus){
    me.unmarkSaving();
    me.$.find('.id').text(xhr.responseText);
  },
  
  storyUpdated: function(xhr, textStatus){
    me.unmarkSaving(); 
    RB.dialog.notice(xhr.responseText) 
  },
  
  triggerEdit: function(event){
    // Get the story since what was clicked was a field
    j = $(this).parents('.story').first();
    
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

/**************************************
  STORY
***************************************/
RB.Story = RB.Object.create(RB.Model, {
  
  initialize: function(el){
    var j;  // This ensures that we use a local 'j' variable, not a global one.
    
    this.$ = j = $(el);
    this.el = el;
    
    // If node is based on #story_template, it doesn't have the story class yet
    // The reason #story_template doesn't have the story class is because we don't
    // want it accidentally included in $('.story') searches
    j.addClass("story");

    // Associate this object with the element for later retrieval
    j.data('this', this);

    // Observe click events in certain fields
    j.find('.editable').live('mouseup', this.triggerEdit);

    // Observe click event on any part of a story
    j.bind('mouseup', this.handleSelect);
        
    this.checkSubjectLength();
  },

  afterSaveEdits: function(){
    
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
  
  close: function(){
    this.$.addClass('closed');
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
        input.removeClass('template');
        input.appendTo(j);
        input.bind('keyup', j.data('this').handleKeyup);
        input.focus(function(){ j.data('focus', $(this).attr('name')); }).blur(function(){ j.data('focus', ''); });
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
    return this.$.children('.id').children().first().text();
  },
  
  getParent: function(){
    return this.$.parents('.backlog').first().data('this');
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

  handleSelect: function(event){
    var j = $(this);
    var me = j.data('this');

    if(!$(event.target).hasClass('editable') && 
       !$(event.target).hasClass('checkbox') &&
       !j.hasClass('editing') &&
       event.target.tagName!='A' &&
       !j.hasClass('dragging')){
      me.setSelection(!me.isSelected());
    }
  },
  
  isClosed: function(){
    return this.$.hasClass('closed');
  },
  
  isNew: function(){
    return this.$.children('.id').text()=="";
  },
  
  isSelected: function(){
    var j = this.$;
    var checkbox = j.find('.checkbox')
    return checkbox.attr('checked');
  },

  markError: function(){
    this.$.addClass('error');
  },
  
  markIfClosed: function(){
    var j = this.$;
    
    if(j.children("select.status_id").children(":selected").hasClass('closed')){
      j.addClass('closed');
    } else {
      j.removeClass('closed');
    }
  },
  
  markSaving: function(){
    this.$.addClass('saving');
  },
  
  open: function(){
    this.$.removeClass('closed');
  },

  refresh: function(obj){
    this.$.html(obj.$.html());
  
    if(obj.isClosed()){
      this.close();
    } else {
      this.open();
    }
  },

  // To be overriden by children objects such as RB.Task
  saveDirectives: function(){
    var j = this.$;
    var prev = this.$.prev();
    var sprint = this.$.parents('.backlog').hasClass('product') ? '' : this.$.parents('.backlog').data('this').getID();
        
    var data = j.find('.editor').serialize() +
               "&prev=" + (prev.length==1 ? this.$.prev().data('this').getID() : '') +
               "&fixed_version_id=" + sprint;

    if( this.isNew() ){
      var url = RB.urlFor['create_story']
    } else {
      var url = RB.urlFor['update_story'].replace(":id", j.children('.id').text())
      data += "&_method=put"
    }

    return {
      url: url,
      data: data
    }
  },

  saveDragResult: function(){
    if(!this.$.hasClass('editing')) this.saveEdits();
  },
  
  saveEdits: function(){
    j = this.$;
    var me = j.data('this');
    editors = j.find('.editor');
    
    // Copy the values from the fields to the proper html elements
    editors.each(function(index){
      editor = $(this);
      fieldName = editor.attr('name');
      if(this.type.match(/select/)){
        j.children('div.' + fieldName).children('.v').text(editor.val())
        j.children('div.' + fieldName).children('.t').text(editor.children(':selected').text());
      // } else if(this.type.match(/textarea/)){
      //   this.setValue('div.' + fieldName + ' .textile', editors[ii].value);
      //   this.setValue('div.' + fieldName + ' .html', '-- will be displayed after save --');
      } else {
        j.children('div.' + fieldName).text(editor.val());
      }
    });

    // Mark the story as closed if so
    me.markIfClosed();

    // Get the save directives. This should be overriden by descendant objects of RB.Story
    var saveDir = this.saveDirectives();

    // We will pop 'me' back when the the ajax call completes
    // This is the only way to remember the RB.Story object since
    // the story element doesn't have an ID yet.
    if(RB.Story.newQueue==null) RB.Story.newQueue = [];
    if(me.isNew()) RB.Story.newQueue.push(me);

    me.unmarkError();
    me.markSaving();
    RB.ajax({
      type: "POST",
      url: saveDir.url,
      data: saveDir.data,
      complete: (me.isNew() ? this.storyCreated : this.storyUpdated) 
    });
    me.endEdit();
    
    var sprint = j.parents('.sprint.backlog');
    if(sprint.size()>0) sprint.data('this').recalcPoints();
    
    this.afterSaveEdits();
  },

  setSelection: function(select){
    this.$.find('.checkbox').attr('checked', select);
  },

  storyCreated: function(xhr, textStatus){
    var me = RB.Story.newQueue.shift(); // Get the RB.Story object back
    me.unmarkSaving();
    
    if(xhr.status!=200){
      me.markError();
    } else {
      var response = $(xhr.responseText);
      me.$.find('.id').html(response.find('.id').html());
      me.$.attr('id', response.attr('id'));
      me.unmarkError();
    }
  },
  
  storyUpdated: function(xhr, textStatus){
    var me = $('#story_' + RB.Factory.initialize(RB.Story, xhr.responseText).getID()).data('this');

    me.unmarkSaving(); 
    if(xhr.status!=200){
      me.markError();
    } else {
      me.unmarkError();
    }
  },

  triggerEdit: function(event){
    // Get the story since what was clicked was a field
    var j = $(this).parents('.story').first();
    
    if(!j.hasClass('editing') && !j.hasClass('dragging')){
      j.data('this').edit();
      
      // Focus on the input corresponding to the field clicked
      j.find( '.' + $(event.currentTarget).attr('fieldname') + '.editor' ).focus();
    }
  },
  
  unmarkError: function(){
    this.$.removeClass('error');
  },
  
  unmarkSaving: function(){
    this.$.removeClass('saving');
  }
  
});

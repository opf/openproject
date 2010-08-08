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

    j.bind('mouseup', this.handleClick);
  },

  afterSaveEdits: function(){
    var c = this.$.find('select.assigned_to_id').children(':selected').attr('color');
    this.$.css('background-color', c);
  },

  // Override RB.Story.checkSubjectLength() and do nothing
  checkSubjectLength: function(){
  },
  
  edit: function(){
    var editor = $("#item_editor").html("");
    var self = this;
    
    this.$.find('.editable').each(function(index){
      var field = $(this);
      var fieldType = field.attr('fieldtype')!=null ? field.attr('fieldtype') : 'input';
      var fieldName = field.attr('fieldname');
      var input;
      
      $(document.createElement("label")).text(fieldName.replace(/_/ig, " ").replace(/ id$/ig,"")).appendTo(editor);
      input = fieldType=='select' ? $('#' + fieldName + '_options').clone(true) : $(document.createElement(fieldType));
      input.removeAttr('id');
      input.attr('name', fieldName);
      input.addClass(fieldName);
      input.addClass('editor');
      input.removeClass('template');
      input.appendTo(editor);
      // input.bind('keyup', j.data('this').handleKeyup);
      
      // Copy the value in the field to the input element
      value = ( fieldType=='select' ? field.children('.v').first().text() : field.text() );
      input.val(value);
    });

    var pos = this.$.offset();
    editor.dialog({
      buttons: {
        "Cancel" : function(){ self.cancelEdit(); $(this).dialog("close") },
        "OK" : function(){ self.saveFromDialog(); $(this).dialog("close") }
      },
      close: function(event, ui){ if(event.which==27) self.cancelEdit() },
      modal: true,
      position: [pos.left - $(document).scrollLeft(), pos.top - $(document).scrollTop()],
      resizable: false,
      title: (this.isNew() ? "New " + (this.$.hasClass('task') ? "Task" : "Impediment") : this.getID())
    });
    
    editor.find(".editor").first().focus();
    editor.parents('.ui-dialog').css('background-color', self.$.css('background-color'));
  },
  
  handleClick: function(event){
    var j = $(this);
    if(!j.hasClass('editing') && !j.hasClass('dragging') && !$(event.target).hasClass('prevent_edit')){
      j.data('this').edit();
    }
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

  markIfClosed: function(){
    if(this.$.parent('td').first().hasClass('closed')){
      this.$.addClass('closed');
    } else {
      this.$.removeClass('closed');
    }
  },

  markSaving: function(){
    this.$.addClass('saving');
  },

  refresh: function(obj){
    this.$.html(obj.$.html());
    this.$.css('background-color', obj.$.css('background-color'));
  
    if(obj.isClosed()){
      this.close();
    } else {
      this.open();
    }
  },

  // Override saveDirectives of RB.Story
  saveDirectives: function(){
    var j = this.$;
    var prev = this.$.prev();
    var cellID = j.parent('td').first().attr('id').split("_");

    var data = j.find('.editor').serialize() +
               "&parent_issue_id=" + cellID[0] +
               "&status_id=" + cellID[1] +
               "&prev=" + (prev.length==1 ? prev.data('this').getID() : '') +
               (this.isNew() ? "" : "&id=" + j.children('.id').text());
    var url = RB.urlFor[(this.isNew() ? 'create_task' : 'update_task')];
    
    return {
      url: url,
      data: data
    }
  },

  saveDragResult: function(){

    if(this.$.parent('td').first().hasClass('closed')){
      // This is only for the purpose of making the Remaining Hours reset
      // instantaneously after dragging to a closed status. The server should
      // still make sure to reset the value to be sure.
      this.$.children('.remaining_hours.editor').val('');
      this.$.children('.remaining_hours.editable').text('');
    }

    if(!this.$.hasClass('editing')) this.saveEdits();
  },
  
  saveFromDialog: function(){
    var editors = this.$.find(".editors").length==0 ? $(document.createElement("div")).addClass("editors").appendTo(this.$) : this.$.find(".editors").first();
    editors.html("");
    editors.append($("#item_editor").children(".editor"));
    this.saveEdits();
  },

  // Override RB.Story.storyUpdated()
  storyUpdated: function(xhr, textStatus){
    var me = $('#task_' + RB.Factory.initialize(RB.Story, xhr.responseText).getID()).data('this');

    me.unmarkSaving();
    if(xhr.status!=200){
      me.markError();
    } else {
      me.unmarkError();
    }
  },

  unmarkSaving: function(){
    this.$.removeClass('saving');
  }  
  
});

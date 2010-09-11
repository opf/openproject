/***************************************
  MODEL
  Common methods for sprint, issue,
  story, task, and impediment
***************************************/

RB.Model = RB.Object.create({

  initialize: function(el){
    var j;  // This ensures that we use a local 'j' variable, not a global one.
    var self = this;
    
    this.$ = j = $(el);
    this.el = el;
  },

  afterCreate: function(data, textStatus, xhr){
    // Do nothing. Child objects may optionally override this
  },

  afterSave: function(data, textStatus, xhr){
    var isNew = this.isNew();
    var result = RB.Factory.initialize(RB.Model, data);
    this.unmarkSaving();
    this.refresh(result);
    if(isNew){
      this.$.attr('id', result.$.attr('id'));
      this.afterCreate(data, textStatus, xhr);
    } else {
      this.afterUpdate(data, textStatus, xhr);
    }
  },
  
  afterUpdate: function(data, textStatus, xhr){
    // Do nothing. Child objects may optionally override this
  },

  beforeSave: function(){
    // Do nothing. Child objects may or may not override this method
  },

  cancelEdit: function(){
    this.endEdit();
    if(this.isNew()){
      this.$.hide('blind');
    }
  },
  
  close: function(){
    this.$.addClass('closed');
  },

  copyFromDialog: function(){
    var editors = this.$.find(".editors").length==0 ? $(document.createElement("div")).addClass("editors").appendTo(this.$) : this.$.find(".editors").first();
    editors.html("");
    editors.append($("#" + this.getType().toLowerCase() + "_editor").children(".editor"));
    this.saveEdits();
  },

  displayEditor: function(editor){
    var pos = this.$.offset();
    var self = this;
    
    editor.dialog({
      buttons: {
        "Cancel" : function(){ self.cancelEdit(); $(this).dialog("close") },
        "OK" : function(){ self.copyFromDialog(); $(this).dialog("close") }
      },
      close: function(event, ui){ if(event.which==27) self.cancelEdit() },
      dialogClass: self.getType().toLowerCase() + '_editor_dialog',
      modal: true,
      position: [pos.left - $(document).scrollLeft(), pos.top - $(document).scrollTop()],
      resizable: false,
      title: (this.isNew() ? this.newDialogTitle() : this.editDialogTitle())
    });
    editor.find(".editor").first().focus();
  },

  edit: function(){
    var editor = this.getEditor();
    
    // 'this' can change below depending on the context.
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
      input.removeClass('helper');
      // Add a date picker if field is a date field
      if (field.hasClass("date")){
        input.datepicker({ changeMonth: true,
                           changeYear: true,
                           closeText: 'Close',
                           dateFormat: 'yy-mm-dd', 
                           firstDay: 1,
                           onClose: function(){ $(this).focus() },
                           selectOtherMonths: true,
                           showAnim:'',
                           showButtonPanel: true,
                           showOtherMonths: true
                       });
        // So that we won't need a datepicker button to re-show it
        input.bind('mouseup', function(event){ $(this).datepicker("show") });
      }
      
      // Copy the value in the field to the input element
      value = ( fieldType=='select' ? field.children('.v').first().text() : field.text() );
      input.val(value);
      
      // Record in the model's root element which input field had the last focus. We will
      // use this information inside RB.Model.refresh() to determine where to return the
      // focus after the element has been refreshed with info from the server.
      input.focus( function(){ self.$.data('focus', $(this).attr('name')) } )
            .blur( function(){ self.$.data('focus', '') } );
      
      input.appendTo(editor);
    });

    this.displayEditor(editor);
    this.editorDisplayed(editor);
    return editor;
  },
  
  // Override this method to change the dialog title
  editDialogTitle: function(){
    return "Edit " + this.getType()
  },
  
  editorDisplayed: function(editor){
    // Do nothing. Child objects may override this.
  },
  
  endEdit: function(){
    this.$.removeClass('editing');
  },
  
  error: function(xhr, textStatus, error){
    this.markError();
    RB.Dialog.msg($(xhr.responseText).find('.errors').html());
    this.processError(xhr, textStatus, error);
  },
  
  getEditor: function(){
    // Create the model editor if it does not yet exist
    var editor_id = this.getType().toLowerCase() + "_editor";
    var editor = $("#" + editor_id).html("");
    if(editor.length==0){
      editor = $( document.createElement("div") )
                 .attr('id', editor_id)
                 .appendTo("body");
    }
    return editor;
  },
  
  getID: function(){
    return this.$.children('.id').children('.v').text();
  },
  
  getType: function(){
    throw "Child objects must override getType()";
  },
    
  handleClick: function(event){
    var field = $(this);
    var model = field.parents('.model').first().data('this');
    var j = model.$;
    if(!j.hasClass('editing') && !j.hasClass('dragging') && !$(event.target).hasClass('prevent_edit')){
      var editor = model.edit();
      editor.find('.' + $(event.currentTarget).attr('fieldname') + '.editor').focus();
    }
  },

  handleSelect: function(event){
    var j = $(this);
    var self = j.data('this');

    if(!$(event.target).hasClass('editable') && 
       !$(event.target).hasClass('checkbox') &&
       !j.hasClass('editing') &&
       event.target.tagName!='A' &&
       !j.hasClass('dragging')){
      self.setSelection(!self.isSelected());
    }
  },

  isClosed: function(){
    return this.$.hasClass('closed');
  },
  
  isNew: function(){
    return this.getID()=="";
  },

  markError: function(){
    this.$.addClass('error');
  },
  
  markIfClosed: function(){
    throw "Child objects must override markIfClosed()";
  },
  
  markSaving: function(){
    this.$.addClass('saving');
  },

  // Override this method to change the dialog title
  newDialogTitle: function(){
    return "New " + this.getType()
  },
    
  open: function(){
    this.$.removeClass('closed');
  },

  processError: function(x,t,e){
    // Do nothing. Feel free to override
  },

  refresh: function(obj){
    this.$.html(obj.$.html());
  
    if(obj.isClosed()){
      this.close();
    } else {
      this.open();
    }
  },

  saveDirectives: function(){
    throw "Child object must implement saveDirectives()"
  },

  saveEdits: function(){
    var j = this.$;
    var self = this;
    var editors = j.find('.editor');
    
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

    // Mark the issue as closed if so
    self.markIfClosed();

    // Get the save directives.
    var saveDir = self.saveDirectives();

    self.beforeSave();

    self.unmarkError();
    self.markSaving();
    RB.ajax({
      type: "POST",
      url: saveDir.url,
      data: saveDir.data,
      success   : function(d,t,x){ self.afterSave(d,t,x) },
      error     : function(x,t,e){ self.error(x,t,e) }
    });
    self.endEdit();
  },
  
  unmarkError: function(){
    this.$.removeClass('error');
  },
  
  unmarkSaving: function(){
    this.$.removeClass('saving');
  }

});
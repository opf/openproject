/**************************************
  ISSUE
***************************************/
RB.Issue = RB.Object.create(RB.Model, {
  
  initialize: function(el){
    var j;
    this.$ = j = $(el);
    this.el = el;
  },

  afterCreate: function(data, textStatus, xhr){
    // Do nothing. Child objects may optionally override this
  },

  afterSave: function(data, textStatus, xhr){
    var isNew = this.isNew();
    this.unmarkSaving();
    this.refresh(RB.Factory.initialize(RB.Issue, data));
    this.afterCreate(data, textStatus, xhr);
    if(isNew){
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
    this.$.removeClass('editing');
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
    editors.append($("#issue_editor").children(".editor"));
    this.saveEdits();
  },

  edit: function(){
    var editor = $("#issue_editor").html("");
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
      
      // Copy the value in the field to the input element
      value = ( fieldType=='select' ? field.children('.v').first().text() : field.text() );
      input.val(value);
    });

    var pos = this.$.offset();
    editor.dialog({
      buttons: {
        "Cancel" : function(){ self.cancelEdit(); $(this).dialog("close") },
        "OK" : function(){ self.copyFromDialog(); $(this).dialog("close") }
      },
      close: function(event, ui){ if(event.which==27) self.cancelEdit() },
      modal: true,
      position: [pos.left - $(document).scrollLeft(), pos.top - $(document).scrollTop()],
      resizable: false,
      title: (this.isNew() ? "New " + this.getType() : this.getID())
    });
    
    editor.find(".editor").first().focus();
    editor.parents('.ui-dialog').css('background-color', self.$.css('background-color'));
  },
  
  endEdit: function(){
    this.$.removeClass('editing');
  },
  
  error: function(xhr, textStatus, error){
    this.markError();
    this.processError(xhr, textStatus, error);
  },
  
  getID: function(){
    return this.$.children('.id').children().first().text();
  },
  
  getType: function(){
    return "Issue";
  },
    
  handleClick: function(event){
    var j = $(this);
    if(!j.hasClass('editing') && !j.hasClass('dragging') && !$(event.target).hasClass('prevent_edit')){
      j.data('this').edit();
    }
  },
  
  handleKeyup: function(event){
    j = $(this).parents('.issue').first();
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
    if(this.isClosed()) this.close();
  },
  
  markSaving: function(){
    this.$.addClass('saving');
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

  saveDragResult: function(){
    this.beforeSaveDragResult();
    if(!this.$.hasClass('editing')) this.saveEdits();
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
  
  triggerEdit: function(event){
    // Get the issue since what was clicked was a field
    var j = $(this).parents('.issue').first();
    
    if(!j.hasClass('editing') && !j.hasClass('dragging')){
      j.data('this').edit();
    }
  },
  
  unmarkError: function(){
    this.$.removeClass('error');
  },
  
  unmarkSaving: function(){
    this.$.removeClass('saving');
  }
  
});

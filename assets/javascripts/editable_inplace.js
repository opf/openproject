RB.EditableInplace = RB.Object.create(RB.Model, {

  displayEditor: function(editor){
    this.$.addClass("editing");
    editor.find(".editor").bind('keyup', this.handleKeyup);
  },

  getEditor: function(){
    // Create the model editor if it does not yet exist
    var editor = this.$.children(".editors").first();
    if(editor.length==0){
      editor = $( document.createElement("div") )
                 .addClass("editors")
                 .appendTo(this.$);
    }
    return editor;
  },

  handleKeyup: function(event){
    j = $(this).parents('.model').first();
    that = j.data('this');

    switch(event.which){
      case 13   : that.saveEdits();   // Enter
                  break;
      case 27   : that.cancelEdit();     // ESC
                  break;
      default   : return true;
    }
  }

});
/**************************************
  STORY
***************************************/
RB.Story = Object.create(RB.Model, {
  
  initialize: function(el){
    this.$ = j = $(el);
    this.el = el;
    
    // Associate this object with the element for later retrieval
    j.data('this', this);

    // Observe double-click events in certain fields
    j.find('.editable').bind('mouseup', this.triggerEdit);
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
  },
  
  getID: function(){
    return this.$.children('.id').text();
  },
  
  getPoints: function(){
    points = parseInt(this.$.children('.points').text());
    return ( isNaN(points) ? 0 : points );
  },
  
  handleKeyup: function(event){
    j = $(this).parents('.story').first();
    that = j.data('this');

    switch(event.which){
      case 13   : that.saveEdits();   // Enter
                  break;
      case 27   : that.endEdit();     // ESC
                  break;
      default   : return true;
    }
  },
  
  markSaving: function(){
    this.$.addClass('saving');
  },
  
  saveEdits: function(){
    j = this.$;
    editors = j.find('.editor');
    
    editors.each(function(index){
      fieldName = $(this).attr('name');
      if(this.type.match(/select/)){
      //   this.setValue('div.' + fieldName + ' .v', editors[ii].value);
      //   this.setValue('div.' + fieldName + ' .t', editors[ii][editors[ii].selectedIndex].text);
      } else if(this.editors[ii].type.match(/textarea/)){
      //   this.setValue('div.' + fieldName + ' .textile', editors[ii].value);
      //   this.setValue('div.' + fieldName + ' .html', '-- will be displayed after save --');
      } else {
      //   this.setValue('div.' + fieldName, editors[ii].value);
      }
    });

    // var status   = this.getChild("select.status_id");
    // var selected = $(status[status.selectedIndex]);
    // if(selected.hasClassName("closed")) {
    //   this.getRoot().addClassName("closed");
    // } else {
    //   this.getRoot().removeClassName("closed");
    // }
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
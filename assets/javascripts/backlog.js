/***************************************
  BACKLOG
***************************************/

RB.Backlog = Object.create(RB.Model, {
    
  initialize: function(el){
    var j;  // This ensures that we use a local 'j' variable, not a global one.
    
    this.$ = j = $(el);
    this.el = el;
    
    // Associate this object with the element for later retrieval
    j.data('this', this);

    // Make the list sortable
    list = this.getList();
    list.sortable({ connectWith: '.stories',
                    placeholder: 'placeholder',
                    forcePlaceholderSize: true,
                    dropOnEmpty: true,
                    start: this.dragStart,
                    stop: this.dragStop,
                    update: this.dragComplete
                    });

    // Observe menu items
    j.find('.new_story').bind('mouseup', this.handleMenuClick);

    // Initialize each item in the backlog
    this.getStories().each(function(index){
      story = RB.Factory.initialize(RB.Story, this); // 'this' refers to an element with class="story"
    });

    // Observe double-click events in certain fields
    if(this.isSprint()){
      j.find('.header').first().find('.editable').bind('mouseup', this.handleMouseup);
    }
  },
  
  dragComplete: function(event, ui) {
    me = $(this).parent('.backlog').data('this'); // Because 'this' represents the sortable ul element
    
    if(me.isSprint()) me.recalcPoints();

    stories = $(event.target).sortable('serialize');    
    dropped = '&dropped=' + ui.item.data('this').getID();
    
    if(ui.sender){
      moveto = '&moveto=' + $(event.target).parent('.backlog').data('this').getID();
    } else {
      moveto = '';
    }

    $.ajax({
        type: "POST",
        url: RB.urlFor['reorder'],
        data: stories + moveto + dropped,
        beforeSend: function(xhr){ ui.item.data('this').markSaving() },
        complete: function(xhr, textStatus){ ui.item.data('this').unmarkSaving() }
    });
  },
  
  dragStart: function(event, ui){ 
    ui.item.addClass("dragging");
  },
  
  dragStop: function(event, ui){ 
    ui.item.removeClass("dragging");  
  },
  
  edit: function(){
    var j = this.$;
    var field, fieldType, fieldName, input, value;
      
    j.addClass('editing');
    
    j.find('.header').first().find('.editable').each(function(index){
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
        if(field.hasClass('datepicker')) input.addClass('datepicker');
        input.addClass('editor');
        input.appendTo(j.find('.header'));
        input.bind('keyup', j.data('this').handleKeyup);
      } else {
        input = input.first();
      }
      
      // Copy the value in the field to the input element
      value = ( fieldType=='select' ? field.children('.v').first().text() : field.text() );
      input.val(value);
    });
    
    // Show the datepicker for date fields
    j.find('.header').find('input.datepicker').each(function(index){
      $(this).datepicker({ changeMonth: true,
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
      $(this).bind('mouseup', function(event){ $(this).datepicker("show") });
    });
  },
  
  endEdit: function(){
    this.$.removeClass('editing');
  },
  
  getID: function(){
    return this.isSprint() ? this.$.attr('id').split('_')[1] : this.$.attr('id');
  },
  
  getStories: function(){
    return this.getList().children(".story");
  },

  getList: function(){
    return $(this.el).children(".stories").first();
  },
  
  handleKeyup: function(event){
    var j = $(this).parents('.backlog').first();
    var that = j.data('this');

    switch(event.which){
      case 13   : that.saveEdits();   // Enter
                  break;
      case 27   : that.endEdit();     // ESC
                  break;
      default   : return true;
    }
  },
  
  handleMouseup: function(event){
    // Get the backlog since what was clicked was a field
    var j = $(this).parents('.backlog').first();
    
    if( !j.hasClass('editing') ){
      j.data('this').edit();
      
      // Focus on the input corresponding to the field clicked
      j.find( '.' + $(event.currentTarget).attr('fieldname') + '.editor' ).focus();
    }
  },

  handleMenuClick: function(event){
    item = $(this);
    if(item.hasClass('new_story')){
      $(this).parents('.backlog').data('this').newStory();
    }
  },
  
  isSprint: function(){
    return $(this.el).hasClass('sprint');
  },
  
  markSaving: function(){
    this.$.addClass('saving');
  },

  loadStoryTemplate: function(){
    $.ajax({
        type: "POST",
        async: false,
        data: "s=s",  // I don't quite understand why the server balks without any data supplied
        url: RB.urlFor['new_story'],
        complete: function(xhr, textStatus){ $(xhr.responseText).removeClass("story").appendTo("#content").wrap("<div id='story_template'/>") } // removeClass() ensures that $(".story") will not include this node
    });
  },
    
  newStory: function(){
    if($('#story_template').size()==0){
      this.loadStoryTemplate();
    }
    
    story = $('#story_template').children().first().clone();
    this.getList().prepend(story);
    o = RB.Factory.initialize(RB.Story, story[0]); // 'this' refers to an element with class="story"
    o.edit();

    //Focus on the input corresponding to the field clicked
    story.find('.editor' ).first().focus();
  },
  
  recalcPoints: function(){
    total = 0;
    this.getStories().each(function(index){
      total += $(this).data('this').getPoints();
    });
    this.$.children('.header').children('.points').text(total);
  },
  
  saveEdits: function(){
    var j = this.$.find('.header').first();
    var me = this.$.data('this');
    var editors = j.find('.editor');
    var editor, fieldName;
    
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
        j.find('div.' + fieldName).text(editor.val());
      }
    });

    $.ajax({
      type: "POST",
      url: RB.urlFor['update_backlog'],
      data: editors.serialize() + "&id=" + j.find('.id').text(),
      beforeSend: function(xhr){ me.markSaving() },
      complete: function(xhr, textStatus){ me.unmarkSaving(); /* RB.dialog.msg(xhr.responseText) */ }
    });
    me.endEdit();
  },
  
  unmarkSaving: function(){
    this.$.removeClass('saving');
  }
});
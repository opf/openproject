// The MIT License
// 
// Copyright (c) 2009 Mark Maglana
// 
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
// 
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

/***************************************
              BACKLOG CLASS
***************************************/

RBL.Backlog = Class.create(RBL.Model, {
  initialize: function($super, element) { 
    this._prefix = "backlog_"
    $super(element);
    
    var myself = this;    // Because 'this' means something else in the each() loop below
    if(!this.isMainBacklog()){
      this.getHeaderChild('.more').observe('mouseup', this.toggleHeight.bind(this));
      this.getHeaderChild('.chart').observe('mouseup', this.toggleChart.bind(this));

      var editables = this.getHeader().select('.editable');
      for(var ii=0; ii < editables.length; ii++){
        editables[ii].observe('click', this.edit.bind(this));
      }
      this.getHeader().select('.calendar-trigger').each(function(trigger){
        trigger.observe('click', myself.edit.bind(myself));
      }); 
    }

    this.getItems().each(function(element){
      var item = new RBL.Item(element);
      myself.registerItem(item); 
    });
    RBL.log("Initialized backlog #"+ this.getValue('.id') +" items.");

    myself.makeSortable(); 
    myself.checkEta();
    RBL.log("Backlog #" + this.getValue('.id') + " initialized.");
  },
  
  applyEdits: function(){
    var notAlreadyClosed = !this.isClosed();
    var status = $("backlog_" + this.getValue(".id") + "_is_closed");
    if(notAlreadyClosed && status.value=="true" && this.getOpenItems().length > 0) {
      this.raiseHasOpenItemsError();
      status.selectedIndex = 0;
      return false
    }
    
    var editors = this.getHeader().select('.editor');
    
    for(var ii=0; ii < editors.length; ii++){
      fieldName = editors[ii].readAttribute('name');
      if(editors[ii].type.match(/select/)){
        this.setValue('div.' + fieldName + ' .v', editors[ii].value);
        this.setValue('div.' + fieldName + ' .t', editors[ii][editors[ii].selectedIndex].text);
      } else {
        this.setValue('div.' + fieldName, editors[ii].value);
      }
    }

    if(this.getHeader().select(".is_closed .v")[0].innerHTML=="true") {
      this.getRoot().addClassName("closed");
    } else {
      this.getRoot().removeClassName("closed");
    }
  },
    
  checkEta: function(){
    // Remove .will_be_late from items in the Main backlog
    if(this.isMainBacklog()){
      this.getRoot().select(".item:not(.task)").each(function(item){
        RBL.Item.find(item).getRoot().removeClassName("will_be_late");
      });
      return true;
    }
    
    // Add .will_be_late to the backlog if eta < due
    var dtstr = "";
    var due = Date.parse(this.getValue(".effective_date").replace(/-/g, "/"));
    
    dtstr = this.getValue(".eta").replace(/-/g, "/").match(/\d\d\d\d\/\d\d\/\d\d/);
    var eta = dtstr==null ? "x" : Date.parse(dtstr[0]);
    
    if(!isNaN(due) && !isNaN(eta) && eta>due){
      this.getRoot().addClassName("will_be_late");
    } else {
      this.getRoot().removeClassName("will_be_late");
    }
    
    velocity = parseInt(this.getValue(".velocity"));
    var myself = this;
    
    this.getRoot().select(".item.closed:not(.task)").each(function(item){
      velocity -= parseInt(RBL.Item.find(item).getValue(".points"));
    });
    
    // Mark items that will not likely be completed within the sprint
    this.getRoot().select(".item:not(.task)").each(function(item){
      i = RBL.Item.find(item);
      if(i.getRoot().hasClassName("closed")) return true;
      velocity -= parseInt(i.getValue(".points"));
      if(!isNaN(velocity) && velocity < 0) { 
        i.getRoot().addClassName("will_be_late");
      } else {
        i.getRoot().removeClassName("will_be_late");
      }
    });
  },
  
  edit: function(event) {
    if(!this.getHeader().hasClassName("editing"))
    {
      this.getHeader().addClassName("editing");
      var editables = this.getHeader().select(".editable"); 
      var field = null;
      var inputyType = null

      for(var ii=0; ii<editables.length; ii++){
        if(editables[ii].hasClassName('ta')){
          inputType = 'textarea';
        } else if (editables[ii].hasClassName('sel')) {
          inputType = 'select';
        } else {
          inputType = 'input';
        }
      
        fieldName = editables[ii].readAttribute('fieldname');
      
        field = this.getHeader().select(inputType + '.' + fieldName)[0];
        if(field==null){
          field = inputType=="select" ? $(fieldName + "_options").cloneNode(true) : new Element(inputType);
          field.writeAttribute('id', 'backlog_' + this.getValue('.id') + '_' + fieldName);
          field.writeAttribute('name', fieldName);
          field.addClassName(fieldName)
          field.addClassName('editor');
          this.getHeader().insert(field);
        }
      
        // The reason for this existing outside the if block above
        // is that some edit fields (i.e. date fields) pre-exist before
        // the first edit() is called. They exist because Redmine's
        // calendar-trigger objects require them to exist before
        // initialization. Yeah. Care for some tea?
        if(!field.hasClassName("observed")){
          field.observe('keydown', this.handleKeyPress.bind(this));
          field.addClassName("observed");
        }
      
        switch(inputType){
          case 'textarea': field.update(editables[ii].innerHTML); break;
          case 'input'   : field.value = editables[ii].innerHTML; break;
          case 'select'  : for(var jj=0; jj < field.length; jj++) { 
                             if(field[jj].value==editables[ii].select('.v')[0].innerHTML) field.selectedIndex=jj;
                           }
        }
      
        if(event!=null && ($(event.target)==editables[ii] || $(event.target).up()==editables[ii])) field.activate();
      }
    }
    
    if(event!=null){ 
      if($(event.target).hasClassName("calendar-trigger")){
        var target = $(event.target).readAttribute('id').match(/[\w\d\s]*(?=_trigger)/)[0];
        $(target).activate();
      }
      event.stop();
    } else {
      this.getHeader().select('.editor')[0].activate();
    }    
  },
  
  endEdit: function(){
    this.getHeader().removeClassName("editing");
  },


  getChart: function(){
    var div = this.getChild('.chart_area');
    var url = RBL.urlFor({ controller: 'charts', 
                           action    : 'show', 
                           backlog_id: this.getValue('.id'), 
                           src       : 'gchart' });
    
    new Ajax.Updater(div, url, { method: 'get', evalScripts: true });
  },

  
  getHeader: function(){
    return this.getChild('.header');
  },
  
  getHeaderChild: function(selector){
    return this.getHeader().select(selector)[0];
  },
  
  getItems: function(){
    return this.getList().select(".item:not(.task)");
  },
  
  getItemIdSequence: function(){
    var sequence = Sortable.sequence(this.getList().identify());
    return sequence;
  },
  
  getList: function() {
    return this.getChild("ul");
  },
  
  getSerializedSequence: function(){
    var sequence = this.getItemIdSequence();
    var serialized = [];
    var id;
    
    for(var ii = 0; ii<sequence.length; ii++){
      id = RBL.Item.find($("item_"+sequence[ii])).getValue('.id');
      serialized.push(id);
    }
    return serialized;
  },  
  
  getOpenItems: function(){
    return this.getList().select(".item:not(.closed):not(.task)");
  },

  handleChange: function(event){
    RBL.log("changed");
  },
  
  handleKeyPress: function(event){
    // Special treatment for textareas
    var processReturnKey = (event.target.type=="textarea" && event.ctrlKey) || event.target.type!="textarea";  
    
    switch(event.keyCode){
      case Event.KEY_ESC   : this.endEdit(); break;
      case Event.KEY_RETURN: if(processReturnKey) { 
                                this.applyEdits(); 
                                this.endEdit(); 
                                this.save(); 
                             } 
                             break;
      default              : return true;
    }
  },

  hideSpinner: function(){
    this.getChild('.header').removeClassName("saving");
  },

  insert: function(item) {
    this.getList().insert({ 'top': item.getRoot() });
    this.registerItem(item);
  },
  
  isClosed: function(){
    return this.getRoot().hasClassName("closed");
  },
  
  isDisplayingChart: function(){
    return this.getRoot().hasClassName("show_chart");
  },
  
  isMainBacklog: function(){
    return this.getValue('.id')==0;
  },
  
  isMaximized: function(){
    return this.getRoot().hasClassName("maximized");
  },

  itemDropped: function(ul) {
    // This method gets called whenever an item is dragged
    // in OR out of the backlog. Thus the condition check below
    
    var item = RBL.Item.find(this._itemDragged);
        
    // Check if item is still in this backlog
    if(this.getValue('.id')==item.getBacklogID()){
      // Yes, item is in this backlog
      this.registerItem(item);
      item.save(); // itemUpdated will be called when this is done
    } else {
      // No, item no longer in this backlog
      this.unregisterItem(item);
      this.checkEta();
      // FIXME: items below the item removed will have to be renumbered
    }
  },
  
  itemUpdated: function(item){
    // Check if the item still belongs to this backlog (to avoid race conditions)
    if(this.getValue('.id')!=RBL.Item.find(this._itemDragged).getBacklogID()) return true;
    
    if(this.isMainBacklog()){
      this.checkEta();
    } else { 
      this.load();
    }
  },
  
  itemDragging: function(element){
    this._itemDragged = element;
  },

  load: function(){
    if(this.isMainBacklog()) return true;
    
    var url = RBL.urlFor({ controller: 'backlogs',
                           action    : 'show',
                           id        : this.getValue('.id') });
    
    this.showSpinner();
    new Ajax.Request(url, {
                     method    : "get",
                     onComplete: this.processDataFromServer.bind(this)
    });
  },

  makeSortable: function(){
    var backlogs = $$(".backlog > ul").map(function(ul){ return ul.identify() });
    var updateHandler = this.itemDropped.bind(this);
    var changeHandler = this.itemDragging.bind(this);
    Sortable.create(this.getChild('ul').identify(), { 
                              containment : backlogs,
                              only        : 'item',
                              dropOnEmpty : true,
                              onUpdate    : updateHandler,
                              onChange    : changeHandler });
  },

  moveItems: function(items){
    var myself = this;    // because 'this' will have a different meaning below
    $(items).each(function(item){
      item.getParentBacklog().unregisterItem(item);
      myself.getList().insert(item.getRoot());
      myself.registerItem(item);
      item.save();
    });
  },

  processDataFromServer: function(transport){
    this.setValue(".eta", "ETA: " + transport.responseJSON.eta);
    this.checkEta();
    this.hideSpinner();
    if(this.isClosed()) this.raiseEvent("close");
  },
  
  raiseHasOpenItemsError: function(){
    RBL.message("ERROR\nMove or close open items first before closing this backlog.");
  },
      
  registerItem: function(item){
    item.observe('update', this.itemUpdated.bind(this), this.getRoot().identify());
  },
  
  save: function(){
    var params = this.toParams();
    var url = RBL.urlFor({ controller: 'backlogs',
                           action    : 'update',
                           id        : this.getValue('.id') });

    this.showSpinner();
    new Ajax.Request(url, {
                     method    : "put",
                     parameters: params,
                     onComplete: this.processDataFromServer.bind(this)
    });
  },

  showSpinner: function(){
    this.getChild('.header').addClassName("saving");
  },

  toggleChart: function(event){
    this.getRoot().toggleClassName("show_chart");
    if(this.isDisplayingChart()) this.getChart();
  },
  
  toggleHeight: function(event){
    this.getRoot().toggleClassName("maximized");
  },
    
  toParams: function(){
    var params = {};
    var fields = this.getHeader().select('.editable');
    
    for(var ii=0; ii<fields.length; ii++){
      params[fields[ii].readAttribute('modelname') + '[' + fields[ii].readAttribute('fieldname') + ']'] =
        (fields[ii].hasClassName('sel') ? fields[ii].select('.v')[0].innerHTML : fields[ii].innerHTML);
    }    
    return params;
  },
  
  unregisterItem: function(item){
    item.stopObserving("update", this.getRoot().identify());
  },
  
});

// Add class methods
Object.keys(RBL.ModelClassMethods).each(function(key){
  RBL.Backlog[key] = RBL.ModelClassMethods[key]; 
});

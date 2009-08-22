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

/**************************************
              ITEM CLASS
***************************************/

RBL.Item = Class.create(RBL.Model, {
  initialize: function($super, element, prefix){
    this._prefix = prefix==null ? "item_" : prefix;
    if(element==null){
      element = $($("item_template").down().cloneNode(true));
      element.writeAttribute({id: this._prefix + (new Date).getTime()})
    }
    $super(element);

    this.getChild('.more').observe('mouseup', this.toggleHeight.bind(this));
    this.getChild('.talk').observe('mouseup', this.toggleDiscussion.bind(this));
    this.getChild('.item_tasks').observe('mousedown', this.preventDrag.bind(this));
    this.getChild('.discussion').observe('mousedown', this.preventDrag.bind(this));
    this.getChild('.add_task').observe('mouseup', this.addTask.bind(this));
    this.getChild('textarea.comment').observe('keydown', this.saveComment.bind(this));
    
    var editables = this.getChildren('.editable');
    for(var ii=0; ii < editables.length; ii++){
      editables[ii].observe('click', this.edit.bind(this));
    }
  },

  addTask: function(event){
    var task = new RBL.Task(null, this);
    this.getTasksList().removeClassName("empty");
    this.getTasksList().insert({ 'top': task.getRoot() });
    task.edit();
  },

  applyEdits: function(){
    var editors = this.getBody().select('.editor');
    
    for(var ii=0; ii < editors.length; ii++){
      fieldName = editors[ii].readAttribute('name');
      if(editors[ii].type.match(/select/)){
        this.setValue('div.' + fieldName + ' .v', editors[ii].value);
        this.setValue('div.' + fieldName + ' .t', editors[ii][editors[ii].selectedIndex].text);
      } else if(editors[ii].type.match(/textarea/)){
        this.setValue('div.' + fieldName + ' .textile', editors[ii].value);
        this.setValue('div.' + fieldName + ' .html', '-- will be displayed after save --');
      } else {
        this.setValue('div.' + fieldName, editors[ii].value);
      }
    }

    var status   = this.getChild("select.status_id");
    var selected = $(status[status.selectedIndex]);
    if(selected.hasClassName("closed")) {
      this.getRoot().addClassName("closed");
    } else {
      this.getRoot().removeClassName("closed");
    }
  },

  clearTasks: function(){
    this.getTasksList().update();
  },
  
  commentsLoaded: function(transport){
    this.getChild("div.comments").update(transport.responseText);
    this.getChild("div.discussion").removeClassName("loading");
  },
  
  commentSaved: function(transport){
    this.getChild("div.comments").insert({ 'top': transport.responseText });
    this.getChild("textarea.comment").value = '';
    this.getChild("div.discussion").removeClassName("loading");
  },
  
  edit: function(event){
    if(event!=null && event.shiftKey) return true;
    
    if (Element.viewportOffset(this.getRoot())[1] > document.viewport.getDimensions().height) 
      Element.scrollTo(this.getRoot());

    this.getRoot().addClassName("editing");    
    
    var editables = this.getBody().select(".editable"); 
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
      
      field = this.getBody().select(inputType + '.' + fieldName)[0];
      if(field==null){
        field = inputType=="select" ? $(fieldName + "_options").cloneNode(true) : new Element(inputType);
        field.writeAttribute('id', '');     // Remove id copied by cloneNode() above.
        field.writeAttribute('name', fieldName);
        field.addClassName(fieldName)
        field.addClassName('editor');
        this.getBody().insert(field);
        field.observe('keydown', this.handleKeyPress.bind(this));
      }
      
      switch(inputType){
        case 'textarea': field.update(editables[ii].select(".textile")[0].innerHTML); break;
        case 'input'   : field.value = editables[ii].innerHTML; break;
        case 'select'  : for(var jj=0; jj < field.length; jj++) { 
                           if(field[jj].value==editables[ii].select('.v')[0].innerHTML) field.selectedIndex=jj;
                         }
      }
      
      if(event!=null && ($(event.target)==editables[ii] || $(event.target).up()==editables[ii])) field.activate();
    }
    
    if(event!=null){ 
      event.stop();
    } else {
      this.getChildren('.editor')[0].activate();
    }
  },

  endEdit: function(){
    this.getRoot().removeClassName('editing');
  },
  
  getBacklogID: function(){
    return this.getParentBacklog().getValue('.id');
  },
  
  getBody: function(){
    return this.getRoot().select(".body")[0];
  },
    
  getNext: function(){
    var el = this.getRoot().next();
    return el==null ? null : RBL.Item.find(el);
  },
  
  getParentBacklog: function(){
    var id = this.getRoot().up(".backlog").down(".header").down(".id").innerHTML;
    return RBL.Backlog.findByID(id);
  },
  
  getParentID: function(){
    return 0;
  },
  
  getPrevious: function(){
    var el = this.getRoot().previous();
    return el==null ? null : RBL.Item.find(el);
  },
  
  getTasksList: function(){
    return this.getChild('.item_tasks');
  },
  
  handleKeyPress: function(event){
    // Special treatment for textareas
    var processReturnKey = (event.target.type=="textarea" && event.ctrlKey) || event.target.type!="textarea";  
    
    switch(event.keyCode){
      case Event.KEY_ESC   : if(this.isNew()) {
                               this.getRoot().slideUp({ duration: 0.25 }); 
                               var el = this.getRoot();
                               new PeriodicalExecuter(function(pe){ el.remove(); pe.stop(); }, 1);
                             } else {
                               this.endEdit();
                             }
                             break;
                             
      case Event.KEY_RETURN: if(processReturnKey) { 
                                this.applyEdits(); 
                                this.endEdit(); 
                                this.save(); 
                             } 
                             break;
                             
      default              : return true;
    }
  },
  
  isClosed: function(){
    return this.getRoot().hasClassName("closed");
  },
  
  isNew: function(){
    return this.getValue(".id")=='';
  },
  
  itemCreated: function(transport){
    var el = new Element('div');
    el.update(transport.responseText);

    this.getChild(".issue_id_container").update(el.select(".issue_id_container")[0].innerHTML);
    this.setValue('.id', el.select(".body .id")[0].innerHTML);
    this.getRoot().writeAttribute('id', this._prefix + this.getValue('.id'));    
    this.register();
    this.getParentBacklog().makeSortable();
    this.markNotSaving();
  },  

  itemUpdated: function(transport){
    var el = new Element('div');
    el.update(transport.responseText);

    this.getChild(".description").update(el.select(".description")[0].innerHTML);
    var highlightStatus = (this.getValue(".issue.status_id .v")!=el.select(".issue.status_id .v")[0].innerHTML);
    this.setValue(".issue.status_id .t", el.select(".issue.status_id .t")[0].innerHTML);
    this.setValue(".issue.status_id .v", el.select(".issue.status_id .v")[0].innerHTML);
    if(highlightStatus) this.getBody().select(".issue.status_id .t")[0].highlight({ startcolor: "#ff3333", endcolor: "#ff3333", duration: 2 }); 
    if(el.select("li.item")[0].hasClassName("closed")) { 
      this.getRoot().addClassName("closed"); 
    } else {
      this.getRoot().removeClassName("closed");
    }
    this.markNotSaving();
    this.raiseEvent("update");
  },
  
  loadComments: function(){
    var url = RBL.urlFor({ controller: 'comments',
                           action    : 'index',
                           item_id   : this.getValue('.id') });
                           
    new Ajax.Request(url, {
                     method    : "get",
                     onComplete: this.commentsLoaded.bind(this)
    });
    this.getChild("div.discussion").addClassName("loading");
  },

  loadTasks: function(){
    this.getTasksList().addClassName("loading");

    var url = RBL.urlFor({ controller: 'tasks',
                           action    : 'index',
                           item_id   : this.getValue('.id') });

    new Ajax.Request(url, {
                     method    : "get",
                     onComplete: this.tasksLoaded.bind(this)
    });
  },

  markNotSaving: function(){
    this.getRoot().removeClassName("saving");
  },

  markSaving: function(){
    this.getRoot().addClassName("saving");
  },
  
  preventDrag: function(event){
    event.stopPropagation();
  },

  registerTask: function(task){
    return true;
  },
  
  save: function(saveCallback){
    var params   = this.toParams();
    var url;
    var callback = null;
    
    this._saveCallback = saveCallback;
    
    if(this.isNew()){
      params["project_id"] = projectID;
      callback = this.itemCreated.bind(this);
      url = RBL.urlFor({ controller: 'items',
                         action    : 'create' });
    } else {
      params["_method"] = "put";
      url = RBL.urlFor({ controller: 'items',
                         action    : 'update',
                         id        : this.getValue('.id') });
      callback = this.itemUpdated.bind(this);
    }

    this.markSaving();
    new Ajax.Request(url, {method: "post", parameters: params, onComplete: callback});
  },
  
  saveComment: function(event){
    if(event.keyCode==Event.KEY_RETURN && event.ctrlKey) {
      var params =  {};
      params["comment"] = this.getChild("textarea.comment").value;
      var url = RBL.urlFor({ controller: 'comments',
                             action    : 'create',
                             item_id   : this.getValue('.id') });
      
      new Ajax.Request(url, {
                       method    : 'post',
                       parameters: params,
                       onComplete: this.commentSaved.bind(this)
      });
      this.getChild("div.discussion").addClassName("loading");
      event.stop();
    } else if (event.keyCode==Event.KEY_ESC) {
      this.getChild("textarea.comment").value = '';
      event.stop();
    }
  },
  
  tasksLoaded: function(transport){
    this.getTasksList().update(transport.responseText);
    if (this.getChildren('li.item.task').length==0){
      this.getTasksList().update("<div class='no_tasks'>No tasks found</div>")
      this.getTasksList().addClassName("empty");
    } else {
      var myself = this;  // Because 'this' will mean something else below
      this.getChildren('li.item.task').each(function(element){
        var task = new RBL.Task(element, myself);
        task.getRoot().removeClassName("maximized");
        myself.registerTask(task);       
      });
    }
    this.getTasksList().removeClassName("loading");
  },
  
  toggleDiscussion: function(event){
    this.getRoot().toggleClassName("discussion");
    if(this.getRoot().hasClassName("discussion")){
      this.loadComments();
      this.getChild("textarea.comment").update("<Type your comment here. Press Ctrl + Enter to post>");
      this.getChild("textarea.comment").activate();
    }
  },
    
  toggleHeight: function(event){
    this.getRoot().toggleClassName("maximized");
    if(this.getRoot().hasClassName("maximized")) {
      if(!this.getParentBacklog().getRoot().hasClassName("main")) this.loadTasks();
    } else {
      this.clearTasks();
    }
  },

  toParams: function(){
    var params = {};
    var fields = this.getBody().select('.editable');
    
    for(var ii=0; ii<fields.length; ii++){
      params[fields[ii].readAttribute('modelname') + '[' + fields[ii].readAttribute('fieldname') + ']'] =
        (fields[ii].hasClassName('sel') ? fields[ii].select('.v')[0].innerHTML : 
          (fields[ii].hasClassName('ta') ? fields[ii].select('.textile')[0].innerHTML : fields[ii].innerHTML) );
    }
    
    params["item[backlog_id]"] = this.getBacklogID();
    params["item[parent_id]"]  = this.getParentID();
    params["prev"]             = this.getPrevious()==null ? null : this.getPrevious().getValue('.id');
    params["next"]             = this.getNext()==null ? null : this.getNext().getValue('.id');
    
    return params;
  },

  updatePointsLabel: function(){
    if(this.getValue(".points")==1){
      this.setValue(".points_label", "pt");
    } else {
      this.setValue(".points_label", "pts");
    }
  },

});

// Add class methods
Object.keys(RBL.ModelClassMethods).each(function(key){
  RBL.Item[key] = RBL.ModelClassMethods[key];
});
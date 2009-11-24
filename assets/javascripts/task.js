/**************************************
              TASK CLASS
***************************************/

RBL.Task = Class.create(RBL.Item, {
  initialize: function($super, element, parentItem){
    this._prefix = "task_";
    this._parentItem = parentItem;
    
    if(element==null){
      element = $("item_template").down().cloneNode(true);
      element.writeAttribute({id: this._prefix + (new Date).getTime()});
      element.addClassName("task");
      element.removeClassName("maximized");
    }
    $super(element, this._prefix);
  },
  
  addTask: function(){
    // NOT IMPLEMENTED
  },
  
  getBacklogID: function(){
    return 0;
  },
  
  getParentItem: function(){
    return this._parentItem;
  },
  
  getParentID: function(){
    return this.getParentItem().getValue('.id');
  },
});

// Add class methods
Object.keys(RBL.ModelClassMethods).each(function(key){
  RBL.Task[key] = RBL.ModelClassMethods[key];
});
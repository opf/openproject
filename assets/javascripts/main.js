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

var RBL = {};

RBL.init = function(){
  var backlog;
  $$(".backlog").each(function(element){
    backlog = new RBL.Backlog(element);
    backlog.observe("close", RBL.processClosedBacklogs, "rbl-main");
  });
  RBL.log("Created backlog objects.");
  
  $("move_items").observe("change", function() { RBL.moveItems(); });
  $("new_item_button").observe("change", function() { RBL.newItem(); });
  $("hide_closed_backlogs").checked = (document.cookie.match(/hide_closed_backlogs=true/)!=null);
  $("hide_closed_backlogs").observe("click", function() { RBL.storePreferences(); RBL.processClosedBacklogs() });
  
  RBL.log("Backlogs Plugin initialized.");
}

document.observe("dom:loaded", function() { RBL.init(); });

/***************************************
              UTILITIES
***************************************/

RBL.destroyClosedBacklog = function(obj){
  RBL.Backlog.find(obj.element).destroy();
}

RBL.log = function(message){
  try{
    console.log(message);
  }
  catch(e){
  }
}

RBL.message = function(message){
  alert(message);
}

RBL.moveItems = function(){
  var moveTo = $("move_items").value;
  var items  = [];
  
  RBL.Item.findAll().each(function(item){
    if(item.getChild(".checkbox").checked) items.push(item);
  });
  
  if($(items).size()>0) RBL.Backlog.findByID(moveTo).moveItems(items);
  
  $("move_items").selectedIndex=0; 
}

RBL.newItem = function(){
  var item = new RBL.Item();
  item.setValue('div.tracker_id .v', $("new_item_button").value);
  $("new_item_button").selectedIndex = 0;
  item.getRoot().hide();
  RBL.Backlog.findByID(0).insert(item);
  item.getRoot().slideDown({ duration: 0.25 });
  RBL.Backlog.findByID(0).makeSortable();
  new PeriodicalExecuter(function(pe){ item.edit(); pe.stop() }, 0.15);
}

RBL.processClosedBacklogs = function(){
  if(document.cookie.match(/hide_closed_backlogs=true/)!=null){
    RBL.Backlog.findAll().each(function(backlog){
      if(backlog.isClosed()){
        backlog.getRoot().fade({ afterFinish: RBL.destroyClosedBacklog });
      }
    });
  }
}

RBL.storePreferences = function(){
  var dateToday  = new Date();
  var expiration = new Date(dateToday.setYear(dateToday.getFullYear() + 1));

  document.cookie = "hide_closed_backlogs=" + ($("hide_closed_backlogs").checked ? "true" : "false") + "; " +
                    "expires=" + expiration.toGMTString();
}


RBL.urlFor = function(options){
  // THINKABOUTTHIS: Is it worth using Rails' routes for this instead?
  var url = '/' + options['controller'] 
  if(options['action']!=null && options['action'].match(/index/)==null) url += '/' + options['action'];
  if(options['id']!=null) url += "/" + options['id'];
  
  var keys = Object.keys(options).select(function(key){ return key!="controller" && key!="action" && key!="id" });    
  if(keys.length>0) url += "?";
  
  keys.each(function(key, index){
    url += key + "=" + options[key];
    if(index<keys.length-1) url += "&";
  });
  
  return url;
}

/***************************************
              BASE CLASS
***************************************/

RBL.Model = Class.create({
  initialize: function(element){
    this.setRoot(element);
    this._observers = {};
    this.register();
  },
  
  destroy: function(){
    // TODO: More cleaning up needed here
    this.getRoot().remove();
  },
  
  register: function(){
    var id = this.getRoot().identify();
    
    var c = this.constructor;
    
    if(!c._instances) c._instances = {};
    c._instances[id] = this;
    
    id = this.getValue('.id');
    if(!c._instancesByRecordID) c._instancesByRecordID = {};
    c._instancesByRecordID[id] = this;    
  },
  
  unregister: function(){
    c._instances[this.getRoot().identify()].destroy();
    c._instancesByRecordID[this.getValue('.id')].destroy();
  },

  setRoot: function(element) {
    this._rootElement = $(element);
  },
  
  getRoot: function() {
    return this._rootElement;
  },  
  
  getChildren: function(selector) {
    return this.getRoot().select(selector);
  },
  
  getChild: function(selector) {
    var tmp = this.getChildren(selector);
    
    switch(tmp.length){
      case 0  : return null  ; break;
      default : return tmp[0]; break;
    }
  },
  
  getValue: function(selector){
    var child = this.getChild(selector);
    if(child==null) return null;
    return child.innerHTML;
  },
  
  setValue: function(selector, value) {
    var oldValue = this.getValue(selector);
    this.getChild(selector).update(value);
    
    var observers = this.getObservers('changed')
    for(var i=0 ; i<observers.length ; i++){
      observers[i](this);
    }
  },
  
  observe: function(event, observer, observer_id){
    if(observer_id==null) RBL.log("WARNING: observe() was supplied with a null observer_id");
    
    if(this._observers[event]==null) this._observers[event]={};
    
    this._observers[event][observer_id]=observer;
  },
  
  getObservers: function(event){
    if(this._observers[event]==null) this._observers[event]={};
    
    var observers = [];
    var myself    = this;
    Object.keys(this._observers[event]).each(function(key){
      observers.push(myself._observers[event][key]);
    });
    
    return observers;
  },

  raiseEvent: function(event){
    var observers = this.getObservers(event);
    for(var i=0 ; i<observers.length ; i++){
      observers[i](this);
    }
  },
  
  stopObserving: function(event, observer_id){
    if(this._observers[event]==null) return true;
    
    delete this._observers[event][observer_id];
  }
});

// Prototype 1.6.x doesn't support inheriting class methods
// yet. So we're defining them in a separate object for now
// and bulk adding them 'manually'
RBL.ModelClassMethods = {
  find: function(obj){
    if(Object.isElement(obj)){
      return this._instances[obj.readAttribute('id')];
    } 
    else {
      return null;
    }
  },
  
  findByID: function(id){
    return this._instancesByRecordID[id];
  },

  findAll: function() {
    return Object.values(this._instances);
  }
}

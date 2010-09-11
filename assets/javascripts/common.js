if(RB==null){
  var RB = {};
}

RB.Object = {
  // Douglas Crockford's technique for object extension
  // http://javascript.crockford.com/prototypal.html
  create: function(o, methods, more_methods){  
      function F(){}
      F.prototype = o;
      obj = new F();
      if(typeof methods == 'object'){
        for(methodName in methods) obj[methodName] = methods[methodName];
      }
      // TODO: Dude, this is embarrasing, I know, but I don't have time to research
      if(typeof more_methods == 'object'){
        for(methodName in more_methods) obj[methodName] = more_methods[methodName];
      }
      return obj;
  }  
}


// Object factory for redmine_backlogs
RB.Factory = RB.Object.create({
  
  initialize: function(objType, el){
    obj = RB.Object.create(objType);
    obj.initialize(el);
    return obj;
  }  
  
});

// Utilities
RB.Dialog = RB.Object.create({
  msg: function(msg){
    dialog = $('#msgBox').size()==0 ? $(document.createElement('div')).attr('id', 'msgBox').appendTo('body') : $('#msgBox');
    dialog.html(msg);
    dialog.dialog({ title: 'Backlogs Plugin',
                    buttons: { "OK": function() { $(this).dialog("close"); } },
                    modal: true
                 });
  },
  
  notice: function(msg){
    if(typeof console != "undefined" && console != null) console.log(msg);
  }
});

RB.ajaxQueue = new Array()
RB.ajaxOngoing = false;

RB.ajax = function(options){
  RB.ajaxQueue.push(options);
  if(!RB.ajaxOngoing){ RB.processAjaxQueue(); }
}

RB.processAjaxQueue = function(){
  var options = RB.ajaxQueue.shift();

  if(options!=null){
    RB.ajaxOngoing = true;
    $.ajax(options);
  }
}

$(document).ajaxComplete(function(event, xhr, settings){
  RB.ajaxOngoing = false;
  RB.processAjaxQueue();
});

// Modify the ajax request before being sent to the server
$(document).ajaxSend(function(event, request, settings) {
  var c = RB.constants;

  settings.data = settings.data || "";
  settings.data += (settings.data ? "&" : "") + "project_id=" + c.project_id;

  if(c.protect_against_forgery){
      settings.data += "&" + c.request_forgery_protection_token + "=" + encodeURIComponent(c.form_authenticity_token);
  }
});

// Abstract the user preference from the rest of the RB objects
// so that we can change the underlying implementation as needed
RB.UserPreferences = RB.Object.create({
  get: function(key){
    return $.cookie(key);
  },
  
  set: function(key, value){
    $.cookie(key, value, { expires: 365 * 10 });
  }
});
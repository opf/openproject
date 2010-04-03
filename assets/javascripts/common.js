if(RB==null){
  var RB = {};
}

// Douglas Crockford's technique for object extension
// http://javascript.crockford.com/prototypal.html
if(typeof Object.create !== 'function'){
    Object.create = function(o, methods){
        function F(){}
        F.prototype = o;
        obj = new F();
        if(typeof methods == 'object'){
          for(methodName in methods) obj[methodName] = methods[methodName];
        }
        return obj;
    };
}

// Object factory for redmine_backlogs
RB.Factory = Object.create({
  
  initialize: function(objType, el){
    obj = Object.create(objType);
    obj.initialize(el);
    return obj;
  }  
  
});

// Common methods for models
RB.Model = Object.create({});

// Utilities
RB.dialog = Object.create({
  msg: function(msg){
    dialog = $('#msgBox').size()==0 ? $(document.createElement('div')).attr('id', 'msgBox').appendTo('#content') : $('#msgBox');
    dialog.text(msg);
    dialog.dialog({ title: 'Backlog Plugin',
                    buttons: { "Ok": function() { $(this).dialog("close"); } },
                    modal: true
                 });
  }
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
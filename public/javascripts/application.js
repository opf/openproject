/* redMine - project management software
   Copyright (C) 2006-2008  Jean-Philippe Lang */

function checkAll (id, checked) {
	var el = document.getElementById(id);
	for (var i = 0; i < el.elements.length; i++) {
    if (el.elements[i].disabled==false) {
      el.elements[i].checked = checked;
    }
	}
}

function addFileField() {
    var f = document.createElement("input");
    f.type = "file";
    f.name = "attachments[]";
    f.size = 30;
        
    p = document.getElementById("attachments_p");
    p.appendChild(document.createElement("br"));
    p.appendChild(f);
}

function showTab(name) {
    var f = $$('div#content .tab-content');
	for(var i=0; i<f.length; i++){
		Element.hide(f[i]);
	}
    var f = $$('div.tabs a');
	for(var i=0; i<f.length; i++){
		Element.removeClassName(f[i], "selected");
	}
	Element.show('tab-content-' + name);
	Element.addClassName('tab-' + name, "selected");
	return false;
}

function setPredecessorFieldsVisibility() {
    relationType = $('relation_relation_type');
    if (relationType && relationType.value == "precedes") {
        Element.show('predecessor_fields');
    } else {
        Element.hide('predecessor_fields');
    }
}

function promptToRemote(text, param, url) {
    value = prompt(text + ':');
    if (value) {
        new Ajax.Request(url + '?' + param + '=' + value, {asynchronous:true, evalScripts:true});
        return false;
    }
}

function collapseScmEntry(id) {
    var els = document.getElementsByClassName(id, 'browser');
	for (var i = 0; i < els.length; i++) {
	   if (els[i].hasClassName('open')) {
	       collapseScmEntry(els[i].id);
	   }
       Element.hide(els[i]);
    }
    $(id).removeClassName('open');
}

function expandScmEntry(id) {
    var els = document.getElementsByClassName(id, 'browser');
	for (var i = 0; i < els.length; i++) {
       Element.show(els[i]);
       if (els[i].hasClassName('loaded') && !els[i].hasClassName('collapsed')) {
            expandScmEntry(els[i].id);
       }
    }
    $(id).addClassName('open');
}

function scmEntryClick(id) {
    el = $(id);
    if (el.hasClassName('open')) {
        collapseScmEntry(id);
        el.addClassName('collapsed');
        return false;
    } else if (el.hasClassName('loaded')) {
        expandScmEntry(id);
        el.removeClassName('collapsed');
        return false;
    }
    if (el.hasClassName('loading')) {
        return false;
    }
    el.addClassName('loading');
    return true;
}

function scmEntryLoaded(id) {
    Element.addClassName(id, 'open');
    Element.addClassName(id, 'loaded');
    Element.removeClassName(id, 'loading');
}

/* shows and hides ajax indicator */
Ajax.Responders.register({
    onCreate: function(){
        if ($('ajax-indicator') && Ajax.activeRequestCount > 0) {
            Element.show('ajax-indicator');
        }
    },
    onComplete: function(){
        if ($('ajax-indicator') && Ajax.activeRequestCount == 0) {
            Element.hide('ajax-indicator');
        }
    }
});

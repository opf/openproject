/* redMine - project management software
   Copyright (C) 2006-2008  Jean-Philippe Lang */

function checkAll (id, checked) {
	var els = Element.descendants(id);
	for (var i = 0; i < els.length; i++) {
    if (els[i].disabled==false) {
      els[i].checked = checked;
    }
	}
}

function toggleCheckboxesBySelector(selector) {
	boxes = $$(selector);
	var all_checked = true;
	for (i = 0; i < boxes.length; i++) { if (boxes[i].checked == false) { all_checked = false; } }
	for (i = 0; i < boxes.length; i++) { boxes[i].checked = !all_checked; }
}

function setCheckboxesBySelector(checked, selector) {
  var boxes = $$(selector);
  boxes.each(function(ele) {
    ele.checked = checked;
  });
}

function showAndScrollTo(id, focus) {
	Element.show(id);
	if (focus!=null) { Form.Element.focus(focus); }
	Element.scrollTo(id);
}

function toggleRowGroup(el) {
	var tr = Element.up(el, 'tr');
	var n = Element.next(tr);
	tr.toggleClassName('open');
	while (n != undefined && !n.hasClassName('group')) {
		Element.toggle(n);
		n = Element.next(n);
	}
}

function collapseAllRowGroups(el) {
  var tbody = Element.up(el, 'tbody');
  tbody.childElements('tr').each(function(tr) {
    if (tr.hasClassName('group')) {
      tr.removeClassName('open');
    } else {
      tr.hide();
    }
  })
}

function expandAllRowGroups(el) {
  var tbody = Element.up(el, 'tbody');
  tbody.childElements('tr').each(function(tr) {
    if (tr.hasClassName('group')) {
      tr.addClassName('open');
    } else {
      tr.show();
    }
  })
}

function toggleAllRowGroups(el) {
	var tr = Element.up(el, 'tr');
  if (tr.hasClassName('open')) {
    collapseAllRowGroups(el);
  } else {
    expandAllRowGroups(el);
  }
}

function toggleFieldset(el) {
	var fieldset = Element.up(el, 'fieldset');
	fieldset.toggleClassName('collapsed');
	Effect.toggle(fieldset.down('div'), 'slide', {duration:0.2});
}

function hideFieldset(el) {
	var fieldset = Element.up(el, 'fieldset');
	fieldset.toggleClassName('collapsed');
	fieldset.down('div').hide();
}

var fileFieldCount = 1;

function addFileField() {
    if (fileFieldCount >= 10) return false
    fileFieldCount++;
    var f = document.createElement("input");
    f.type = "file";
    f.name = "attachments[" + fileFieldCount + "][file]";
    f.size = 30;
    var d = document.createElement("input");
    d.type = "text";
    d.name = "attachments[" + fileFieldCount + "][description]";
    d.size = 60;
    var dLabel = new Element('label');
    dLabel.addClassName('inline');
    // Pulls the languge value used for Optional Description
    dLabel.update($('attachment_description_label_content').innerHTML)
    p = document.getElementById("attachments_fields");
    p.appendChild(document.createElement("br"));
    p.appendChild(f);
    p.appendChild(dLabel);
    dLabel.appendChild(d);

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

function moveTabRight(el) {
	var lis = Element.up(el, 'div.tabs').down('ul').childElements();
	var tabsWidth = 0;
	var i;
	for (i=0; i<lis.length; i++) {
		if (lis[i].visible()) {
			tabsWidth += lis[i].getWidth() + 6;
		}
	}
	if (tabsWidth < Element.up(el, 'div.tabs').getWidth() - 60) {
		return;
	}
	i=0;
	while (i<lis.length && !lis[i].visible()) {
		i++;
	}
	lis[i].hide();
}

function moveTabLeft(el) {
	var lis = Element.up(el, 'div.tabs').down('ul').childElements();
	var i = 0;
	while (i<lis.length && !lis[i].visible()) {
		i++;
	}
	if (i>0) {
		lis[i-1].show();
	}
}

function displayTabsButtons() {
	var lis;
	var tabsWidth = 0;
	var i;
	$$('div.tabs').each(function(el) {
		lis = el.down('ul').childElements();
		for (i=0; i<lis.length; i++) {
			if (lis[i].visible()) {
				tabsWidth += lis[i].getWidth() + 6;
			}
		}
		if ((tabsWidth < el.getWidth() - 60) && (lis[0].visible())) {
			el.down('div.tabs-buttons').hide();
		} else {
			el.down('div.tabs-buttons').show();
		}
	});
}

function setPredecessorFieldsVisibility() {
    relationType = $('relation_relation_type');
    if (relationType && (relationType.value == "precedes" || relationType.value == "follows")) {
        Element.show('predecessor_fields');
    } else {
        Element.hide('predecessor_fields');
    }
}

function promptToRemote(text, param, url) {
    value = prompt(text + ':');
    if (value) {
        new Ajax.Request(url + '?' + param + '=' + encodeURIComponent(value), {asynchronous:true, evalScripts:true});
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

function randomKey(size) {
	var chars = new Array('0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z', 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z');
	var key = '';
	for (i = 0; i < size; i++) {
  	key += chars[Math.floor(Math.random() * chars.length)];
	}
	return key;
}

function observeParentIssueField(url) {
  new Ajax.Autocompleter('issue_parent_issue_id',
                         'parent_issue_candidates',
                         url,
                         { minChars: 1,
                           frequency: 0.5,
                           paramName: 'q',
                           updateElement: function(value) {
                             document.getElementById('issue_parent_issue_id').value = value.id;
                           }});
}

function observeRelatedIssueField(url) {
  new Ajax.Autocompleter('relation_issue_to_id',
                         'related_issue_candidates',
                         url,
                         { minChars: 1,
                           frequency: 0.5,
                           paramName: 'q',
                           updateElement: function(value) {
                             document.getElementById('relation_issue_to_id').value = value.id;
                           },
                           parameters: 'scope=all'
                           });
}

function setVisible(id, visible) {
  var el = $(id);
  if (el) {if (visible) {el.show();} else {el.hide();}}
}

function observeProjectModules() {
  var f = function() {
    /* Hides trackers and issues custom fields on the new project form when issue_tracking module is disabled */
    var c = ($('project_enabled_module_names_issue_tracking').checked == true);
    setVisible('project_trackers', c);
    setVisible('project_issue_custom_fields', c);
  };
  
  Event.observe(window, 'load', f);
  Event.observe('project_enabled_module_names_issue_tracking', 'change', f);
}

/*
 * Class used to warn user when leaving a page with unsaved textarea
 * Author: mathias.fischer@berlinonline.de
*/

var WarnLeavingUnsaved = Class.create({
	observedForms: false,
	observedElements: false,
	changedForms: false,
	message: null,
	
	initialize: function(message){
		this.observedForms = $$('form');
		this.observedElements =  $$('textarea');
		this.message = message;
		
		this.observedElements.each(this.observeChange.bind(this));
		this.observedForms.each(this.submitAction.bind(this));
		
		window.onbeforeunload = this.unload.bind(this);
	},
	
	unload: function(){
		if(this.changedForms)
      return this.message;
	},
	
	setChanged: function(){
    this.changedForms = true;
	},
	
	setUnchanged: function(){
    this.changedForms = false;
	},
	
	observeChange: function(element){
    element.observe('change',this.setChanged.bindAsEventListener(this));
	},
	
	submitAction: function(element){
    element.observe('submit',this.setUnchanged.bindAsEventListener(this));
	}
});

/* 
 * 1 - registers a callback which copies the csrf token into the
 * X-CSRF-Token header with each ajax request.  Necessary to 
 * work with rails applications which have fixed
 * CVE-2011-0447
 * 2 - shows and hides ajax indicator
 */
Ajax.Responders.register({
    onCreate: function(request){
        var csrf_meta_tag = $$('meta[name=csrf-token]')[0];

        if (csrf_meta_tag) {
            var header = 'X-CSRF-Token',
                token = csrf_meta_tag.readAttribute('content');

            if (!request.options.requestHeaders) {
              request.options.requestHeaders = {};
            }
            request.options.requestHeaders[header] = token;
          }

        if ($('ajax-indicator') && Ajax.activeRequestCount > 0) {
            Element.show('ajax-indicator');
        }
    },
    onComplete: function(){
        if ($('ajax-indicator') && Ajax.activeRequestCount == 0) {
            Element.hide('ajax-indicator');
        }
        addClickEventToAllErrorMessages();
    }
});

function hideOnLoad() {
  $$('.hol').each(function(el) {
  	el.hide();
	});
}

function addClickEventToAllErrorMessages() {
  $$('a.afocus').each(function(a) {
    $(a).observe('click', function(event) {
      var field;
      field = $($(a).readAttribute('href').substr(1));
      if (field == null) {
        // Cut off '_id' (necessary for select boxes)
        field = $($(a).readAttribute('href').substr(1).concat('_id'));
      }
      if (field) {
        field.down('input, textarea, select').focus();
      }
      Event.stop(event);
      return false;
    });
  });
}
$(document).observe('dom:loaded', function() {
  // Set focus on first error message
  var focus = $$('a.afocus').first();
  if (focus != undefined) {
    focus.focus();
  }
  // Focus on field with error
  addClickEventToAllErrorMessages();
});

Event.observe(window, 'load', hideOnLoad);

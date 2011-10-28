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
    }
});

function hideOnLoad() {
  $$('.hol').each(function(el) {
  	el.hide();
	});
}

Event.observe(window, 'load', hideOnLoad);

/* jQuery code from #263 */
/* TODO: integrate with existing code and/or refactor */
jQuery(document).ready(function($) {

	// a few constants for animations speeds, etc.
	var animRate = 100;

	// header menu hovers
	$("#account .drop-down").hover(function() {
		$(this).addClass("open").find("ul").slideDown(animRate);
		$("#top-menu").toggleClass("open");
	}, function() {
		$(this).removeClass("open").find("ul").slideUp(animRate);
		$("#top-menu").toggleClass("open");
	});

	// show/hide header search box
  // TODO: switch to live after upgrading jQuery version. "flicker" bug.
	$("#account a.search").click(function() {
		var searchWidth = $("#account-nav").width();

		$(this).toggleClass("open");
		$("#nav-search").width(searchWidth).slideToggle(animRate, function(){
			$("#nav-search-box").select();
		});

		return false;
	});

	// file table thumbnails
	$("table a.has-thumb").hover(function() {
		$(this).removeAttr("title").toggleClass("active");

		// grab the image dimensions to position it properly
		var thumbImg = $(this).find("img");
		var thumbImgLeft = -(thumbImg.outerWidth() );
		var thumbImgTop = -(thumbImg.height() / 2 );
		thumbImg.css({top: thumbImgTop, left: thumbImgLeft}).show();

	}, function() {
		$(this).toggleClass("active").find("img").hide();
	});

	// show/hide the files table
	$(".attachments h4").click(function() {
	  $(this).toggleClass("closed").next().slideToggle(animRate);
	});

	// custom function for sliding the main-menu. IE6 & IE7 don't handle sliding very well
	$.fn.mySlide = function() {
		if (parseInt($.browser.version, 10) < 8 && $.browser.msie) {
			// no animations, just toggle
			this.toggle();
			// this forces IE to redraw the menu area, un-bollocksing things
			$("#main-menu").css({paddingBottom:5}).animate({paddingBottom:0}, 10);
		} else {
			this.slideToggle(animRate);
		}

		return this;
	};

	// open and close the main-menu sub-menus
	$("#main-menu li:has(ul) > a").not("ul ul a")
		.append("<span class='toggler'></span>")
		.click(function() {

			$(this).toggleClass("open").parent().find("ul").not("ul ul ul").mySlide();

			return false;
	});

	// submenu flyouts
	$("#main-menu li li:has(ul)").hover(function() {
		$(this).find(".profile-box").show();
		$(this).find("ul").slideDown(animRate);
	}, function() {
		$(this).find("ul").slideUp(animRate);
	});

	// add filter dropdown menu
	$(".button-large:has(ul) > a").click(function(event) {
		var tgt = $(event.target);

		// is this inside the title bar?
		if (tgt.parents().is(".title-bar")) {
			$(".title-bar-extras:hidden").slideDown(animRate);
		}

		$(this).parent().find("ul").slideToggle(animRate);

		return false;
	});

    // Connect new issue lightbox to the New Issue link but only when
    // on the issues list.
    $('a.issues.selected + ul a.new-issue').click(function() {
        // Make sure the Issue form is on the page
        if ($('#issue-form-wrap').size() > 0) {
            tb_show("Open a new issue", "#TB_inline?inlineId=issue-form-wrap&amp;height=510&amp;width=735", false);

            // Taken from the custom override code
            // call the resize function after 350 milliseconds. should be enough time to have it load, but not too much so that there's lag.
            setTimeout(resizeNewIssue,350);

            return false;
        }
    });
});

/* Appended 2009-07-07 */
var animRate = 100;

// returns viewport height
jQuery.viewportHeight = function() {
     return self.innerHeight ||
        jQuery.boxModel && document.documentElement.clientHeight ||
        document.body.clientHeight;
};

// resizes the new issue box.
function resizeNewIssue() {

	jQuery("#TB_window").height(jQuery.viewportHeight() - 40).css({top: '20px', marginTop: '0' });
	jQuery("#TB_ajaxContent").height(jQuery("#TB_window").height() - jQuery("#TB_title").height() );
	jQuery("#TB_window #issue-form").height(jQuery("#TB_ajaxContent").height() );
	jQuery("#TB_window #issue-form .box").height(jQuery("#TB_ajaxContent").height() - jQuery("#issue-form .tracker").outerHeight() - jQuery("#issue-form .submit").outerHeight() - 20 );

	// hacks for thickbox not picking up the proper width from the query string
	if (jQuery("#TB_ajaxContent").width() < 735 ) {
		jQuery("#TB_ajaxContent").width(735);
		jQuery("#TB_window").css({width: 765, marginLeft: -(765/2)});
	}

}

function issuesPageActions() {


	tb_init("a.thickbox");

	// call the resize function after 350 milliseconds. should be enough time to have it load, but not too much so that there's lag.
	jQuery(".new-issue a.thickbox").click(function() {
		setTimeout(resizeNewIssue,350);
	});

	// tooltip handler


	jQuery("table.issues td.issue").mouseover(function(event) {

		// first check if .js-tooltip elements have been wrapped in the crucial .js-tooltip-inner div
		// if not, the first hover will add everything
		if (!jQuery(".js-tooltip:first > div").hasClass("js-tooltip-inner") ) {
			jQuery(".js-tooltip").wrapInner("<div class='js-tooltip-inner'></div>").append("<span class='arrow'></span>"); // give an extra div for styling

		}

		var $thisTR = jQuery(event.target).parents("tr");
		var trPos = $thisTR.position();
		var tTarget = $thisTR.attr("id");

		jQuery("form#issue-list").toggleClass("tooltip-active");
		jQuery("div[rel="+tTarget+"]").css('top', trPos.top).show();

	});

	jQuery("table.issues td.issue").mouseout(function(event) {
		var $thisTR = jQuery(event.target).parents("tr");
		var tTarget = $thisTR.attr("id");

		jQuery("form#issue-list").toggleClass("tooltip-active");
		jQuery("div[rel="+tTarget+"]").hide();
	});

}

jQuery(document).ready(function($) {

	// header animation replacement - no animation, straight appear/hide
	$("#account .drop-down").unbind('mouseenter').unbind("mouseleave"); //remove the current animated handlers

	// remove .drop-down class from empty dropdowns
	$("#account .drop-down").each(function(index) {
		if ($(this).find("li").size() < 1) {
			$(this).removeClass("drop-down");
		}
	});

	$("#account .drop-down").hover(function() {
		$(this).addClass("open").find("ul").show();
		$("#top-menu").addClass("open");

		// wraps long dropdown menu in an overflow:auto div to keep long project lists on the page
		var $projectDrop = $("#account .drop-down:has(.projects) ul");

		// only do the wrapping if it's the project dropdown, and more than 15 items
		if ( $projectDrop.children().size() > 15 && $(this).find("> a").hasClass("projects") ) {

			var overflowHeight = 15 * $projectDrop.find("li:eq(1)").outerHeight() - 2;

			$projectDrop
				.wrapInner("<div class='overflow'></div>").end()
				.find(".overflow").css({overflow: 'auto', height: overflowHeight, position: 'relative'})
				.find("li a").css('paddingRight', '25px');

				// do hack-y stuff for IE6 & 7. don't ask why, I don't know.
				if (parseInt($.browser.version, 10) < 8 && $.browser.msie) {

					$projectDrop.find(".overflow").css({width: 325, zoom: '1'});
					$projectDrop.find("li a").css('marginLeft', '-15px');
					$("#top-menu").css('z-index', '10000');
				}

		}


	}, function() {
		$(this).removeClass("open").find("ul").hide();
		$("#top-menu").removeClass("open");
	});

	// deal with potentially problematic super-long titles
	$(".title-bar h2").css({paddingRight: $(".title-bar-actions").outerWidth() + 15 });

	// move email checkbox inside div.box
	$("#issue-form > p").clone().appendTo("#issue-form .box");
	$("#issue-form > p").remove();

	// move preview area inside div.box
	if ($("form#issue-list").size() > 0 ) { // only do this on the issue list page
		$("#issue-form-wrap #preview").remove();
		$("#issue-form .box").append("<div id='preview' class='wiki'></div>");
	}




	// resize after a window resize.
	$(window).resize(function() {
		resizeNewIssue();
	});




	// rejigger the main-menu sub-menu functionality.
	$("#main-menu .toggler").remove(); // remove the togglers so they're inserted properly later.

	$("#main-menu li:has(ul) > a").not("ul ul a")
		// 1. unbind the current click functions
		.unbind("click")
		// 2. wrap each in a span that we'll use for the new click element
		.wrapInner("<span class='toggle-follow'></span>")
		// 3. reinsert the <span class="toggler"> so that it sits outside of the above
		.append("<span class='toggler'></span>")
		// 4. attach a new click function that will follow the link if you clicked on the span itself and toggle if not
		.click(function(event) {

			if (!$(event.target).hasClass("toggle-follow") ) {
				$(this).toggleClass("open").parent().find("ul").not("ul ul ul").mySlide();
				return false;
			}
		});



});

// Sets the save_and_close field to tell Redmine to either keep the
// thickbox open or close it when a New Issue is saved successfully.
function setCloseAfterSave(on) {
    var field = $('save_and_close');
    if (field) {
        if (on) {
            field.value = '1';
        } else {
            field.value = '0';
        }
    }
}

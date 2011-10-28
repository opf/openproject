jQuery.noConflict();

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
	$("#account a.search").click(function() {
		var searchWidth = $("#account-nav").width();

		$(this).toggleClass("open");
		$("#nav-search").width(searchWidth).slideToggle(animRate, function(){
			$("#nav-search-box").select();
		});

		return false;
	});

	// issue table info tooltips
	$(".js-tooltip").wrapInner("<div class='js-tooltip-inner'></div>").append("<span class='arrow'></span>"); // give an extra div for styling

	$("table.issues td.issue").hover(function(event) {
		var $thisTR = $(event.target).parents("tr");
		var trPos = $thisTR.position();
		var tTarget = $thisTR.attr("id");

		$("form#issue-list").toggleClass("tooltip-active");
		$("div[rel="+tTarget+"]").css('top', trPos.top).fadeIn(animRate*2, function(){
			//ie cleartype uglies
			if ($.browser.msie) {this.style.removeAttribute('filter'); };
			});

	}, function(event) {
		var $thisTR = $(event.target).parents("tr");
		var tTarget = $thisTR.attr("id");

		$("form#issue-list").toggleClass("tooltip-active");
		$("div[rel="+tTarget+"]").hide();
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

	// suckerfish-esque on those issue dropdown menus for IE6
	if (parseInt($.browser.version, 10) < 7 && $.browser.msie) {
		$(".issue-dropdown li").hover(function() {
			$(this).toggleClass("hover");
		}, function() {
			$(this).toggleClass("hover");
		});
	}

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

	// first remove current event handlers for tooltips - overrides original common.js functionality. Remove this once common.js is merged with this.
	$("table.issues td.issue").unbind('mouseenter').unbind("mouseleave");

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

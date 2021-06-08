// Legacy code ported from app/assets/javascripts/application.js.erb
// Do not add stuff here, but ideally remove into components whenver changes are necessary
export function setupServerResponse() {
  initMainMenuExpandStatus();
  focusFirstErroneousField();
  activateFlashNotice();
  activateFlashError();
  autoHideFlashMessage();
  flashCloseHandler();

  jQuery(document).ajaxComplete(activateFlashNotice);
  jQuery(document).ajaxComplete(activateFlashError);

  /*
  * 1 - registers a callback which copies the csrf token into the
  * X-CSRF-Token header with each ajax request.  Necessary to
  * work with rails applications which have fixed
  * CVE-2011-0447
  * 2 - shows and hides ajax indicator
  */
  jQuery(document).ajaxSend(function (event, request) {
    if (jQuery(event.target.activeElement!).closest('[ajax-indicated]').length &&
      jQuery('ajax-indicator')) {
      jQuery('#ajax-indicator').show();
    }

    var csrf_meta_tag = jQuery('meta[name=csrf-token]');

    if (csrf_meta_tag) {
      var header = 'X-CSRF-Token',
        token = csrf_meta_tag.attr('content');

      request.setRequestHeader(header, token!);
    }

    request.setRequestHeader('X-Authentication-Scheme', "Session");
  });

  // ajaxStop gets called when ALL Requests finish, so we won't need a counter as in PT
  jQuery(document).ajaxStop(function () {
    if (jQuery('#ajax-indicator')) {
      jQuery('#ajax-indicator').hide();
    }
    addClickEventToAllErrorMessages();
  });

  // show/hide the files table
  jQuery(".attachments h4").click(function () {
    jQuery(this).toggleClass("closed").next().slideToggle(100);
  });

  let resizeTo:any = null;
  jQuery(window).on('resize', function () {
    // wait 200 milliseconds for no further resize event
    // then readjust breadcrumb

    if (resizeTo) {
      clearTimeout(resizeTo);
    }
    resizeTo = setTimeout(function () {
      jQuery(window).trigger('resizeEnd');
    }, 200);
  });

  // Do not close the login window when using it
  jQuery('#nav-login-content').click(function (event) {
    event.stopPropagation();
  });

  // Set focus on first error message
  var error_focus = jQuery('a.afocus').first();
  var input_focus = jQuery('.autofocus').first();
  if (error_focus !== undefined) {
    error_focus.focus();
  } else if (input_focus !== undefined) {
    input_focus.focus();
    if (input_focus[0].tagName === "INPUT") {
      input_focus.select();
    }
  }
  // Focus on field with error
  addClickEventToAllErrorMessages();

  // Click handler for formatting help
  jQuery(document.body).on('click', '.formatting-help-link-button', function () {
    window.open(window.appBasePath + '/help/wiki_syntax',
      "",
      "resizable=yes, location=no, width=600, height=640, menubar=no, status=no, scrollbars=yes"
    );
    return false;
  });
}

function flashCloseHandler() {
  jQuery('body').on('click keydown touchend', '.close-handler,.notification-box--close', function (e) {
    if (e.type === 'click' || e.which === 13) {
      jQuery(this).parent('.flash, .errorExplanation, .notification-box')
        .not('.persistent-toggle--notification')
        .remove();
    }
  });
}

function autoHideFlashMessage() {
  setTimeout(function () {
    jQuery('.flash.autohide-notification').remove();
  }, 5000);
}

function addClickEventToAllErrorMessages() {
  jQuery('a.afocus').each(function () {
    var target = jQuery(this);
    target.click(function (evt) {
      var field = jQuery('#' + target.attr('href')!.substr(1));
      if (field === null) {
        // Cut off '_id' (necessary for select boxes)
        field = jQuery('#' + target.attr('href')!.substr(1).concat('_id'));
      }
      target.unbind(evt);
      return false;
    });
  });
}

function initMainMenuExpandStatus() {
  const wrapper = jQuery('#wrapper');
  const upToggle = jQuery('ul.menu_root.closed li.open a.arrow-left-to-project');

  if (upToggle.length === 1 && wrapper.hasClass('hidden-navigation')) {
    upToggle.trigger('click');
  }
}

function activateFlash(selector:any) {
  const flashMessages = jQuery(selector);

  flashMessages.each(function (ix, e) {
    const flashMessage = jQuery(e);
    flashMessage.show();
  });
}

function activateFlashNotice() {

  activateFlash('.flash');
}

function activateFlashError() {
  activateFlash('.errorExplanation[role="alert"]');
}

function focusFirstErroneousField() {
  const firstErrorSpan = jQuery('span.errorSpan').first();
  const erroneousInput = firstErrorSpan.find('*').filter(":input");

  erroneousInput.trigger('focus');
}


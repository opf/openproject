// Legacy code ported from app/assets/javascripts/application.js.erb
// Do not add stuff here, but ideally remove into components whenever changes are necessary
export function setupServerResponse() {
  initMainMenuExpandStatus();
  focusFirstErroneousField();
  activateFlashNotice();
  activateFlashError();

  jQuery(document).ajaxComplete(activateFlashNotice);
  jQuery(document).ajaxComplete(activateFlashError);

  /*
  * 1 - registers a callback which copies the csrf token into the
  * X-CSRF-Token header with each ajax request.  Necessary to
  * work with rails applications which have fixed
  * CVE-2011-0447
  * 2 - shows and hides ajax indicator
  */
  jQuery(document).ajaxSend((event, request) => {
    if (jQuery(event.target.activeElement!).closest('[ajax-indicated]').length
      && jQuery('ajax-indicator')) {
      jQuery('#ajax-indicator').show();
    }

    const csrf_meta_tag = jQuery('meta[name=csrf-token]');

    if (csrf_meta_tag) {
      const header = 'X-CSRF-Token';
      const token = csrf_meta_tag.attr('content');

      request.setRequestHeader(header, token!);
    }

    request.setRequestHeader('X-Authentication-Scheme', 'Session');
  });

  // ajaxStop gets called when ALL Requests finish, so we won't need a counter as in PT
  jQuery(document).ajaxStop(() => {
    if (jQuery('#ajax-indicator')) {
      jQuery('#ajax-indicator').hide();
    }
    addClickEventToAllErrorMessages();
  });

  // show/hide the files table
  jQuery('.attachments h4').click(function () {
    jQuery(this).toggleClass('closed').next().slideToggle(100);
  });

  let resizeTo:any = null;
  jQuery(window).on('resize', () => {
    // wait 200 milliseconds for no further resize event
    // then readjust breadcrumb

    if (resizeTo) {
      clearTimeout(resizeTo);
    }
    resizeTo = setTimeout(() => {
      jQuery(window).trigger('resizeEnd');
    }, 200);
  });

  // Do not close the login window when using it
  jQuery('#nav-login-content').click((event) => {
    event.stopPropagation();
  });

  // Set focus on first error message
  const error_focus = jQuery('a.afocus').first();
  const input_focus = jQuery('.autofocus').first();
  if (error_focus !== undefined) {
    error_focus.focus();
  } else if (input_focus !== undefined) {
    input_focus.focus();
    if (input_focus[0].tagName === 'INPUT') {
      input_focus.select();
    }
  }
  // Focus on field with error
  addClickEventToAllErrorMessages();

  // Click handler for formatting help
  jQuery(document.body).on('click', '.formatting-help-link-button', () => {
    window.open(`${window.appBasePath}/help/wiki_syntax`,
      '',
      'resizable=yes, location=no, width=600, height=640, menubar=no, status=no, scrollbars=yes');
    return false;
  });
}

function addClickEventToAllErrorMessages() {
  jQuery('a.afocus').each(function () {
    const target = jQuery(this);
    target.click((evt) => {
      let field = jQuery(`#${target.attr('href')!.substr(1)}`);
      if (field === null) {
        // Cut off '_id' (necessary for select boxes)
        field = jQuery(`#${target.attr('href')!.substr(1).concat('_id')}`);
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

  flashMessages.each((ix, e) => {
    const flashMessage = jQuery(e);
    flashMessage.show();
  });
}

function activateFlashNotice() {
  activateFlash('.op-toast[role="alert"]');
}

function activateFlashError() {
  activateFlash('.errorExplanation[role="alert"]');
}

function focusFirstErroneousField() {
  const firstErrorSpan = jQuery('span.errorSpan').first();
  const erroneousInput = firstErrorSpan.find('*').filter(':input');

  erroneousInput.trigger('focus');
}

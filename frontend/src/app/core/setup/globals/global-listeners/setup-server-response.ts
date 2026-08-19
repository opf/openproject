// Legacy code ported from app/assets/javascripts/application.js.erb
import { delegate } from '@knowledgecode/delegate';
import { showElement } from 'core-app/shared/helpers/dom-helpers';
import { slideDown, slideUp } from 'es6-slide-up-down';

// Do not add stuff here, but ideally remove into components whenever changes are necessary
export function setupServerResponse() {
  // show/hide the files table
  document.querySelectorAll<HTMLHeadingElement>('.attachments h4').forEach((heading) => {
    heading.addEventListener('click', () => {
      const closed = heading.classList.toggle('closed');
      const nextElement = heading.nextElementSibling as HTMLElement;
      if (closed) {
        slideUp(nextElement, 100);
      } else {
        slideDown(nextElement, 100);
      }
    });
  });

  let resizeTo:any = null;
  window.addEventListener('resize', () => {
    // wait 200 milliseconds for no further resize event
    // then readjust breadcrumb

    if (resizeTo) {
      clearTimeout(resizeTo);
    }
    resizeTo = setTimeout(() => {
      window.dispatchEvent(new CustomEvent('resizeEnd', { bubbles: true }));
    }, 200);
  });

  // Do not close the login window when using it
  document.querySelector('#nav-login-content')?.addEventListener('click', (event) => {
    event.stopPropagation();
  });

  // Set focus on first error message
  const error_focus = document.querySelector<HTMLAnchorElement>('a.afocus');
  const input_focus = document.querySelector<HTMLElement>('.autofocus');
  if (error_focus) {
    error_focus.focus();
  } else if (input_focus) {
    input_focus.focus();
    if (input_focus instanceof HTMLInputElement) {
      input_focus.select();
    }
  }
  // Focus on field with error
  addClickEventToAllErrorMessages();

  // Click handler for formatting help
  delegate(document.body).on('click', '.formatting-help-link-button', (event) => {
    window.open(
      `${window.appBasePath}/help/wiki_syntax`,
      '',
      'resizable=yes, location=no, width=600, height=640, menubar=no, status=no, scrollbars=yes'
    );
    event.preventDefault();
    event.stopPropagation();
  });
}

function addClickEventToAllErrorMessages() {
  document.querySelectorAll('a.afocus').forEach((anchor) => {
    anchor.addEventListener('click', function (evt) {
      evt.preventDefault();

      const href = anchor.getAttribute('href');
      if (!href?.startsWith('#')) return;

      const id = href.substring(1);
      let field = document.getElementById(id);

      if (!field) {
        // Try with `_id` suffix (needed for select boxes)
        field = document.getElementById(id + '_id');
      }

      if (field) {
        field.focus();
      }
    }, { once: true });
  });
}

export function initMainMenuExpandStatus() {
  const wrapper = document.querySelector('#wrapper')!;
  const upToggle = document.querySelector<HTMLAnchorElement>('ul.menu_root.closed li.open a.arrow-left-to-project');

  if (upToggle && wrapper.classList.contains('hidden-navigation')) {
    upToggle.click();
  }
}

function activateFlash(selector:string) {
  const flashMessages = document.querySelectorAll<HTMLElement>(selector);

  flashMessages.forEach((flashMessage) => { showElement(flashMessage); });
}

export function activateFlashNotice() {
  activateFlash('.op-toast[role="alert"]');
}

export function activateFlashError() {
  activateFlash('.errorExplanation[role="alert"]');
}

export function focusFirstErroneousField() {
  const firstErrorSpan = document.querySelector('span.errorSpan');
  const erroneousInput = firstErrorSpan?.querySelector<HTMLElement>('input, select, textarea, button');

  erroneousInput?.focus();
}

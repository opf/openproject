import * as Turbo from '@hotwired/turbo';

export namespace TurboHelpers {
  let progressBarTimeout:number | undefined;

  function getProgressBar():Turbo.ProgressBar {
    return (Turbo.session.adapter as Turbo.BrowserAdapter).progressBar;
  }

  export function showProgressBar() {
    const progressBar = getProgressBar();
    progressBar.setValue(0);
    progressBarTimeout ??= window.setTimeout(() => {
      progressBar.show();
    }, Turbo.config.drive.progressBarDelay);
  }

  export function hideProgressBar() {
    const progressBar = getProgressBar();
    progressBar.setValue(1);
    progressBar.hide();
    if (progressBarTimeout != null) {
      window.clearTimeout(progressBarTimeout);
      progressBarTimeout = undefined;
    }
  }

  export function scrubScriptElements(element:HTMLElement|DocumentFragment) {
    const cspNonce = document.getElementsByName('csp-nonce')[0]?.getAttribute('content') || '';

    element
      .querySelectorAll('script')
      .forEach((script) => {
        const nonce = script.getAttribute('nonce');

        if (!(nonce && nonce === cspNonce)) {
          console.warn('Removing script element %O because it does not match our nonce', script);
          script.remove();
        }
      });
  }
}

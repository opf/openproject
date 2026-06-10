import { TurboHelpers } from './helpers';

export function addTurboEventListeners() {
  // Close the primer dialog when the form inside has been submitted with a success response.
  //
  // If you want to keep the dialog open even after a successful form submission, you can add the
  // `data-keep-open-on-submit="true"` attribute to the dialog element.
  //
  // It is necessary to close the primer dialog using the `close()` method, otherwise
  // it will leave an overflow:hidden attribute on the body, which prevents scrolling on the page.
  //
  // Also, we will dispatch a custom `dialog:close` event when the dialog is closed.
  document.addEventListener('turbo:submit-end', (event) => {
    const { detail: { success }, target } = event;

    if (success && target instanceof HTMLFormElement) {
      const dialog = target.closest('dialog')!;

      if (dialog) {
        if (dialog.dataset.keepOpenOnSubmit !== 'true') {
          dialog.close('close-event-already-dispatched');
          document.dispatchEvent(new CustomEvent('dialog:close', { detail: { dialog, submitted: true } }));
        }
      }
    }
  });

  // Append turbo nonce for drive requests
  document.addEventListener('turbo:before-fetch-request', (event) => {
    // Turbo Drive does not send a referrer like turbolinks used to, so let's simulate it here
    const { headers } = event.detail.fetchOptions;
    headers['Turbo-Referrer'] = window.location.href;
    headers['X-Turbo-Nonce'] = document.getElementsByName('csp-nonce')[0]?.getAttribute('content') ?? '';
  });

  // Turbo adds nonces to all scripts, even though we want to explicitly pass nonces
  // https://github.com/hotwired/turbo/issues/294#issuecomment-2633216052
  // We remove them manually as a workaround
  // in Handle Turbo Drive page loads (full reloads)
  document.addEventListener('turbo:before-render', (event) => {
    TurboHelpers.scrubScriptElements(event.detail.newBody);
  }, { capture: true });

  // in Turbo Streams (partial updates)
  document.addEventListener('turbo:before-stream-render', (event) => {
    const fallbackToDefaultActions = event.detail.render;

    event.detail.render = async (streamElement) => {
      const content = streamElement.templateElement.content;
      TurboHelpers.scrubScriptElements(content);

      const result = await fallbackToDefaultActions(streamElement);
      document.dispatchEvent(new CustomEvent('op:turbo-stream-rendered'));
      return result;
    };
  });

  // in Turbo Frames (when they load new content)
  document.addEventListener('turbo:before-frame-render', (event) => {
    TurboHelpers.scrubScriptElements(event.detail.newFrame);
  }, { capture: true });
}

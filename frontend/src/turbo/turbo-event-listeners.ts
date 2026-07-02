import { TurboHelpers } from './helpers';

export function addTurboEventListeners(doc:Document = document, signal?:AbortSignal) {
  // Close the primer dialog when the form inside has been submitted with a success response.
  //
  // If you want to keep the dialog open even after a successful form submission, you can add the
  // `data-keep-open-on-submit="true"` attribute to the dialog element.
  //
  // It is necessary to close the primer dialog using the `close()` method, otherwise
  // it will leave an overflow:hidden attribute on the body, which prevents scrolling on the page.
  //
  // Also, we will dispatch a custom `dialog:close` event when the dialog is closed.
  doc.addEventListener('turbo:submit-end', (event) => {
    const { detail: { success }, target } = event;

    if (success && target instanceof HTMLFormElement) {
      const dialog = target.closest('dialog')!;

      if (dialog) {
        if (dialog.dataset.keepOpenOnSubmit !== 'true') {
          dialog.close('close-event-already-dispatched');
          doc.dispatchEvent(new CustomEvent('dialog:close', { detail: { dialog, submitted: true } }));
        }
      }
    }
  }, { signal });

  // Append turbo nonce for drive requests
  doc.addEventListener('turbo:before-fetch-request', (event) => {
    // Turbo Drive does not send a referrer like turbolinks used to, so let's simulate it here
    const { headers } = event.detail.fetchOptions;
    headers['Turbo-Referrer'] = window.location.href;
    headers['X-Turbo-Nonce'] = doc.getElementsByName('csp-nonce')[0]?.getAttribute('content') ?? '';
  }, { signal });

  // Turbo adds nonces to all scripts, even though we want to explicitly pass nonces
  // https://github.com/hotwired/turbo/issues/294#issuecomment-2633216052
  // We remove them manually as a workaround
  // in Handle Turbo Drive page loads (full reloads)
  doc.addEventListener('turbo:before-render', (event) => {
    TurboHelpers.scrubScriptElements(event.detail.newBody);
  }, { capture: true, signal });

  // in Turbo Streams (partial updates)
  doc.addEventListener('turbo:before-stream-render', (event) => {
    const fallbackToDefaultActions = event.detail.render;

    event.detail.render = async (streamElement) => {
      const content = streamElement.templateElement.content;
      TurboHelpers.scrubScriptElements(content);

      const result = await fallbackToDefaultActions(streamElement);
      doc.dispatchEvent(new CustomEvent('op:turbo-stream-rendered'));
      return result;
    };
  }, { signal });

  // in Turbo Frames (when they load new content)
  doc.addEventListener('turbo:before-frame-render', (event) => {
    TurboHelpers.scrubScriptElements(event.detail.newFrame);
  }, { capture: true, signal });
}

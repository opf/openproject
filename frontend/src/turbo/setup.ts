import "../typings/shims.d.ts"
import * as Turbo from '@hotwired/turbo';
import { ModalDialogElement } from '@openproject/primer-view-components/app/components/primer/alpha/modal_dialog';
import { registerDialogStreamAction } from './dialog-stream-action';

// Disable default turbo-drive for now as we don't need it for now AND it breaks angular routing
Turbo.session.drive = false;
// Start turbo
Turbo.start();

// Error handling when "Content missing" returned
document.addEventListener('turbo:frame-missing', (event:CustomEvent) => {
  const { detail: { response, visit } } = event as { detail:{ response:Response, visit:(url:string) => void } };
  event.preventDefault();
  visit(response.url);
});

// Close the primer dialog when the form inside has been submitted with a success response
// It is necessary to close the primer dialog using the `close()` method, otherwise
// it will leave an overflow:hidden attribute on the body, which prevents scrolling on the page.
document.addEventListener('turbo:submit-end', (event:CustomEvent) => {
  const { detail: { success }, target } = event as { detail:{ success:boolean }, target:EventTarget };

  if (success && target instanceof HTMLFormElement) {
    const dialog = target.closest('modal-dialog') as ModalDialogElement;
    dialog && dialog.close(true);
  }
});

registerDialogStreamAction();

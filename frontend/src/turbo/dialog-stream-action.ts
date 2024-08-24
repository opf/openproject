import { StreamActions, StreamElement } from '@hotwired/turbo';

export function registerDialogStreamAction() {
  StreamActions.dialog = function dialogStreamAction(this:StreamElement) {
    const content = this.templateElement.content;
    const dialog = content.querySelector('dialog') as HTMLDialogElement;
    // Set a temporary width so the dialog reflows after opening
    dialog.style.width = '0px';

    document.body.append(content);

    // Auto-show the modal
    dialog.showModal();

    // Remove the element on close
    dialog.addEventListener('close', () => {
      if (dialog.parentElement?.tagName === 'DIALOG-HELPER') {
        dialog.parentElement.remove();
      } else {
        dialog.remove();
      }
    });

    setTimeout(() => {
      dialog.style.removeProperty('width');
    }, 10);
  };
}

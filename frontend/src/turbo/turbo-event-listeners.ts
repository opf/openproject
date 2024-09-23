export function addTurboEventListeners() {
  // Close the primer dialog when the form inside has been submitted with a success response.
  //
  // If you want to keep the dialog open even after a successful form submission, you can add the
  // `data-keep-open-on-submit="true"` attribute to the dialog element.
  //
  // It is necessary to close the primer dialog using the `close()` method, otherwise
  // it will leave an overflow:hidden attribute on the body, which prevents scrolling on the page.
  document.addEventListener('turbo:submit-end', (event:CustomEvent) => {
    const { detail: { success }, target } = event as { detail:{ success:boolean }, target:EventTarget };

    if (success && target instanceof HTMLFormElement) {
      const dialog = target.closest('dialog') as HTMLDialogElement;

      if (dialog && dialog.dataset.keepOpenOnSubmit !== 'true') {
        dialog.close();
      }
    }
  });
}

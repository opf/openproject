import { ApplicationController } from 'stimulus-use';
import { TurboBeforeVisitEvent } from '@hotwired/turbo';

export class BeforeunloadController extends ApplicationController {
  private abortController = new AbortController();

  connect() {
    super.connect();

    const { signal } = this.abortController;

    window.addEventListener('beforeunload', this, { signal });
    document.addEventListener('turbo:before-visit', this, { signal });
    document.addEventListener('turbo:submit-end', this, { signal });
    document.addEventListener('turbo:load', this, { signal });
    document.addEventListener('turbo:render', this, { signal });
    document.addEventListener('submit', this, { signal });
  }

  disconnect() {
    this.abortController.abort();
  }

  handleEvent(evt:Event) {
    switch (evt.type) {
      case 'beforeunload':
      case 'turbo:before-visit':
        this.beforeunloadHandler(evt);
        break;
      case 'turbo:submit-end':
      case 'turbo:load':
      case 'turbo:render':
        window.OpenProject.pageState = 'pristine';
        break;
      case 'submit':
        window.OpenProject.pageState = 'submitted';
        break;
      default:
        break;
    }
  }

  private beforeunloadHandler(evt:BeforeUnloadEvent|TurboBeforeVisitEvent) {
    const hasUnsavedChanges = evt.type === 'turbo:before-visit'
      ? window.OpenProject.pageHasUnsavedChanges
      : window.OpenProject.pageWasEdited;

    if (!hasUnsavedChanges) {
      return;
    }

    if (window.confirm(I18n.t('js.text_are_you_sure_to_cancel'))) {
      return;
    }

    // Cancel the event
    evt.preventDefault();

    // Chrome requires returnValue to be set
    if (evt.type === 'beforeunload') {
      evt.returnValue = '';
    }
  }
}

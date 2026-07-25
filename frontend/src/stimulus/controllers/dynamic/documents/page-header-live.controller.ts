import { LiveController } from '@camertron/live-component';
import { OPToastEvent } from 'core-app/shared/components/toaster/toast-event';

export default class PageHeaderLiveController extends LiveController {
  static targets = ['titleInput'];

  declare readonly titleInputTarget:HTMLInputElement;
  declare readonly hasTitleInputTarget:boolean;

  edit(event:Event):void {
    event.preventDefault();
    this.render((component) => { component.props.state = 'edit'; })
      .catch((error:unknown) => this.reportRenderFailure(error));
  }

  cancel(event:Event):void {
    event.preventDefault();
    this.render((component) => { component.props.state = 'show'; })
      .catch((error:unknown) => this.reportRenderFailure(error));
  }

  save(event:Event):void {
    event.preventDefault();
    const title = this.titleInputTarget.value;
    this.render((component) => {
      component.call('update_title', { title });
    }).catch((error:unknown) => this.reportRenderFailure(error));
  }

  // Also runs on connect(): the library calls after_update() at the end of
  // propagate_state, and connect() reaches it via
  // propagate_state_from_element(). Both effects below are idempotent, but
  // the name implies a narrower trigger than it has.
  after_update():void {
    if (this.hasTitleInputTarget) {
      this.titleInputTarget.focus();
      this.titleInputTarget.select();
    }

    const url = new URL(window.location.href);
    if (url.searchParams.has('state')) {
      url.searchParams.delete('state');
      window.history.replaceState({}, document.title, url.toString());
    }
  }

  // LiveController's task queue logs a render failure but re-rejects it, so
  // every caller has to handle the rejection itself. Without this, a 4xx/5xx,
  // a dropped connection, an expired session (302 to the sign-in page) and a
  // permission-denied empty body -- which makes the library's own state
  // lookup throw -- all present identically as "the button did nothing".
  private reportRenderFailure(error:unknown):void {
    console.error('LiveComponent render failed', error);

    window.dispatchEvent(new CustomEvent(OPToastEvent, {
      detail: {
        message: I18n.t('js.error.internal'),
        type: 'error',
      },
    }));
  }
}

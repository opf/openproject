import * as Turbo from '@hotwired/turbo';

export namespace TurboHelpers {
  export function showProgressBar() {
    Turbo.session.adapter.formSubmissionStarted();
  }

  export function hideProgressBar() {
    Turbo.session.adapter.formSubmissionFinished();
  }
}

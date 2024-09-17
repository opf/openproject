/* eslint-disable */
// @ts-nocheck
import * as Turbo from '@hotwired/turbo';

export function applyTurboNavigationPatch() {
  Turbo.FrameElement.delegateConstructor.prototype.proposeVisitIfNavigatedWithAction = function (frame, action = null) {
    this.action = action;

    if (this.action) {
      // const pageSnapshot = PageSnapshot.fromElement(frame).clone()
      // @ts-ignore
      const pageSnapshot = Turbo.PageSnapshot.fromElement(frame).clone();
      const { visitCachedSnapshot } = frame.delegate;

      // frame.delegate.fetchResponseLoaded = async (fetchResponse) => {
      frame.delegate.fetchResponseLoaded = (fetchResponse) => {
        if (frame.src) {
          const { statusCode, redirected } = fetchResponse;
          // const responseHTML = await fetchResponse.responseHTML
          const responseHTML = frame.ownerDocument.documentElement.outerHTML;
          const response = { statusCode, redirected, responseHTML };
          const options = {
            response,
            visitCachedSnapshot,
            willRender: false,
            updateHistory: false,
            restorationIdentifier: this.restorationIdentifier,
            snapshot: pageSnapshot,
          };

          if (this.action) options.action = this.action;

          // session.visit(frame.src, options)
          Turbo.session.visit(frame.src, options);
        }
      }
    }
  }
}

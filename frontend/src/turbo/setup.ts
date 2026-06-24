import * as Turbo from '@hotwired/turbo';
import TurboPower from 'turbo_power';
import { registerDialogStreamAction } from './dialog-stream-action';
import { addTurboEventListeners } from './turbo-event-listeners';
import { registerFlashStreamAction } from './flash-stream-action';
import { registerLiveRegionStreamAction } from './live-region-stream-action';
import { registerInputCaptionStreamAction } from './input-caption-stream-action';
import { registerDispatchEventStreamAction } from './dispatch-event-stream-action';
import { addTurboGlobalListeners } from './turbo-global-listeners';
import { applyTurboNavigationPatch } from './turbo-navigation-patch';
import { debugLog, whenDebugging } from 'core-app/shared/helpers/debug_output';
import { getTurboEvents } from './utils';
import { StreamActions } from '@hotwired/turbo';
import { addTurboAngularWrapper } from 'core-turbo/turbo-angular-wrapper';
import { registerActionMenuMorphRemount } from './action-menu-morph-remount';

Turbo.session.drive = true;
Turbo.config.drive.progressBarDelay = 100;

// Start turbo
Turbo.start();

// Register logging of events
whenDebugging(() => {
  getTurboEvents()
    .filter((name) => name !== 'turbo:before-stream-render')
    .forEach((name:string) => {
      document.addEventListener(name, (event) => {
        debugLog(`[TURBO EVENT ${name}] %O`, event);
      });
    });

  document.addEventListener('turbo:before-stream-render', (event) => {
    const { detail: { newStream:stream } } = event;
    debugLog(`[TURBO EVENT turbo-before-stream-render] ${stream.action.toUpperCase()} target=${stream.target} %O`, event);
  });
});

// Register our own actions
addTurboEventListeners();
addTurboGlobalListeners();
registerActionMenuMorphRemount();
registerDialogStreamAction();
registerFlashStreamAction();
registerLiveRegionStreamAction();
registerInputCaptionStreamAction();
registerDispatchEventStreamAction();
addTurboAngularWrapper();

StreamActions.reloadPage = function reloadPage() {
  window.location.reload();
};

// Apply navigational patch
// https://github.com/hotwired/turbo/issues/1300
applyTurboNavigationPatch();

// Register only the turbo-power stream actions we actually use
TurboPower.register('push_state', TurboPower.Actions.push_state, StreamActions);
TurboPower.register('turbo_frame_set_src', TurboPower.Actions.turbo_frame_set_src, StreamActions);
TurboPower.register('redirect_to', TurboPower.Actions.redirect_to, StreamActions);
TurboPower.register('set_dataset_attribute', TurboPower.Actions.set_dataset_attribute, StreamActions);
TurboPower.register('set_title', TurboPower.Actions.set_title, StreamActions);
TurboPower.register('reload', TurboPower.Actions.reload, StreamActions);

// Error handling when "Content missing" returned
document.addEventListener('turbo:frame-missing', (event) => {
  const { detail: { response, visit } } = event;
  event.preventDefault();
  whenDebugging(() => {
    const frameId = event.target instanceof Element ? event.target.id : undefined;
    const message = frameId ? `no turbo-frame#${frameId} in` : 'destination frame id missing for';
    console.error(`${message} response from ${response.url}`);
  });
  void visit(response.url, {});
});

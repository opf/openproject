import '../typings/shims.d.ts';
import * as Turbo from '@hotwired/turbo';
import TurboPower from 'turbo_power';
import { registerDialogStreamAction } from './dialog-stream-action';
import { addTurboEventListeners } from './turbo-event-listeners';
import { registerFlashStreamAction } from './flash-stream-action';
import { addTurboGlobalListeners } from './turbo-global-listeners';
import { applyTurboNavigationPatch } from './turbo-navigation-patch';
import { debugLog, whenDebugging } from 'core-app/shared/helpers/debug_output';
import { TURBO_EVENTS } from './constants';

Turbo.session.drive = true;
Turbo.setProgressBarDelay(100);

// Start turbo
Turbo.start();

// Register logging of events
whenDebugging(() => {
  TURBO_EVENTS.forEach((name:string) => {
    document.addEventListener(name, (event) => {
      debugLog(`[TURBO EVENT ${name}] %O`, event);
    });
  });
});

// Register our own actions
addTurboEventListeners();
addTurboGlobalListeners();
registerDialogStreamAction();
registerFlashStreamAction();

// Apply navigational patch
// https://github.com/hotwired/turbo/issues/1300
applyTurboNavigationPatch();

// Register turbo power actions
TurboPower.initialize(Turbo.StreamActions);

// Error handling when "Content missing" returned
document.addEventListener('turbo:frame-missing', (event:CustomEvent) => {
  const { detail: { response, visit } } = event as { detail:{ response:Response, visit:(url:string) => void } };
  event.preventDefault();
  visit(response.url);
});

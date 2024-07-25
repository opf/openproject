import '../typings/shims.d.ts';
import * as Turbo from '@hotwired/turbo';
import TurboPower from 'turbo_power';
import { registerDialogStreamAction } from './dialog-stream-action';
import { registerHistoryAction } from './history-action';
import { addTurboEventListeners } from './turbo-event-listeners';

// Disable default turbo-drive for now as we don't need it for now AND it breaks angular routing
Turbo.session.drive = false;
// Start turbo
Turbo.start();

// Register our own actions
addTurboEventListeners();
registerDialogStreamAction();
registerHistoryAction();

// Register turbo power actions
TurboPower.initialize(Turbo.StreamActions);

// Error handling when "Content missing" returned
document.addEventListener('turbo:frame-missing', (event: CustomEvent) => {
  const { detail: { response, visit } } = event as { detail: { response: Response, visit: (url: string) => void } };
  event.preventDefault();
  visit(response.url);
});

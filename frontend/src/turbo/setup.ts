import '../typings/shims.d.ts';
import * as Turbo from '@hotwired/turbo';
import { registerDialogStreamAction } from './dialog-stream-action';
import { addTurboEventListeners } from './turbo-event-listeners';

// Disable default turbo-drive for now as we don't need it for now AND it breaks angular routing
Turbo.session.drive = false;
// Start turbo
Turbo.start();

addTurboEventListeners();
registerDialogStreamAction();

// Error handling when "Content missing" returned
document.addEventListener('turbo:frame-missing', (event:CustomEvent) => {
  const { detail: { response, visit } } = event as { detail:{ response:Response, visit:(url:string) => void } };
  event.preventDefault();
  visit(response.url);
});

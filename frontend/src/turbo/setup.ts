import "../typings/shims.d.ts"
import * as Turbo from '@hotwired/turbo';
import { registerDialogStreamAction } from './dialog-stream-action';
import { addTurboEventListeners } from './turbo-event-listeners';

// Disable default turbo-drive for now as we don't need it for now AND it breaks angular routing
Turbo.session.drive = false;
// Start turbo
Turbo.start();

addTurboEventListeners();
registerDialogStreamAction();

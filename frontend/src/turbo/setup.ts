import * as Turbo from '@hotwired/turbo'; 
import '@hotwired/turbo-rails';
// Disable default turbo-drive for now as we don't need it for now AND it breaks angular routing
Turbo.session.drive = false;
// Start turbo
Turbo.start();
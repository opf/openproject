import * as Turbo from '@hotwired/turbo';
// Disable default turbo-drive for now as we don't need it for now AND it breaks angular routing
Turbo.session.drive = false;
// Start turbo
Turbo.start();

// Error handling when "Content missing" returned
document.addEventListener('turbo:frame-missing', (event:CustomEvent) => {
  const { detail: { response, visit } } = event as { detail:{ response:Response, visit:(url:string) => void } };
  event.preventDefault();
  visit(response.url);
});

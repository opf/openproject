import { Component } from '@angular/core';

@Component({
  template: `
<div className="spot-action-bar">
  <div className="spot-action-bar--left">
    <a
      className="spot-link"
      href="#"
    >Some link</a>
  </div>
  <div className="spot-action-bar--right">
    <button
      type="button"
      className="spot-button"
    >
    </button>
  </div>
</div>,
`,
})
export class SbActionBarExampleComponent {}

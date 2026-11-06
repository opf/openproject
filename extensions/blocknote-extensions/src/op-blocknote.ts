import React from 'react';
import { createRoot } from 'react-dom/client';
import App from './App';

import mantineStyles from '@blocknote/mantine/style.css?url';
import { ShadowDomWrapper } from '../lib';

class BlockNoteElement extends HTMLElement {
  private mount:HTMLDivElement;
  private reactRoot:ReturnType<typeof createRoot> | null = null;

  constructor() {
    super();

    const shadowRoot = this.attachShadow({ mode: 'open' });
    this.mount = document.createElement('div');
    shadowRoot.appendChild(this.mount);

    const link = document.createElement('link');
    link.rel = 'stylesheet';
    link.href = mantineStyles;
    shadowRoot.appendChild(link);
  }

  connectedCallback() {
    this.reactRoot = createRoot(this.mount);

    this.reactRoot.render(
      React.createElement(
        ShadowDomWrapper,
        { target: this.mount },
        React.createElement(App)
      )
    );
  }

  disconnectedCallback() {
    if (this.reactRoot) {
      this.reactRoot.unmount();
      this.reactRoot = null;
    }
  }
}

if (!customElements.get('op-block-note')) {
  customElements.define('op-block-note', BlockNoteElement);
}


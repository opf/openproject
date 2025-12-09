import React from 'react';
import { createRoot } from 'react-dom/client';
import App from './App';

import mantineStyles from '@blocknote/mantine/style.css?url';

class BlockNoteElement extends HTMLElement {
  private mount: HTMLDivElement;

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
    const root = createRoot(this.mount);

    root.render(this.BlockNoteReactContainer());
  }

  BlockNoteReactContainer() {
    return React.createElement(App);
  }
}

customElements.define('op-block-note', BlockNoteElement);


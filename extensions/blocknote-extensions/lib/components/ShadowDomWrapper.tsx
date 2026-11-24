import type { PropsWithChildren } from 'react';
import { createGlobalStyle, StyleSheetManager } from 'styled-components';

interface ShadowDomWrapperProps {
  target:ShadowRoot | HTMLElement;
}

const ProseMirrorBaseStyles = createGlobalStyle`
  .ProseMirror {
    overflow-wrap: break-word;
  }

  /* Tiptap injects these into the document head, which a shadow root does not see. */
  .ProseMirror-hideselection *::selection {
    background: transparent;
  }

  .ProseMirror-hideselection * {
    caret-color: transparent;
  }

  .ProseMirror-gapcursor {
    display: none;
    pointer-events: none;
    position: absolute;
    margin: 0;
  }

  .ProseMirror-gapcursor:after {
    content: "";
    display: block;
    position: absolute;
    top: -2px;
    width: 20px;
    border-top: 1px solid black;
    animation: ProseMirror-cursor-blink 1.1s steps(2, start) infinite;
  }

  @keyframes ProseMirror-cursor-blink {
    to {
      visibility: hidden;
    }
  }

  .ProseMirror-focused .ProseMirror-gapcursor {
    display: block;
  }
`;

export const ShadowDomWrapper = ({ children, target }:PropsWithChildren<ShadowDomWrapperProps>) => (
  <StyleSheetManager target={target}>
    <>
      <ProseMirrorBaseStyles />
      {children}
    </>
  </StyleSheetManager>
);

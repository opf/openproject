import type { PropsWithChildren } from 'react';
import { createGlobalStyle, StyleSheetManager } from 'styled-components';
import gapCursorStyles from 'prosemirror-gapcursor/style/gapcursor.css?inline';

interface ShadowDomWrapperProps {
  target:ShadowRoot | HTMLElement;
}

const ProseMirrorBaseStyles = createGlobalStyle`
  .ProseMirror {
    overflow-wrap: break-word;
  }

  /* Tiptap injects these into the document head, which a shadow root does not see. Copied
     rather than imported: prosemirror-view's stylesheet also brings a selected-node outline
     that Tiptap leaves out. */
  .ProseMirror-hideselection *::selection {
    background: transparent;
  }

  .ProseMirror-hideselection * {
    caret-color: transparent;
  }

  ${gapCursorStyles}

  /* Upstream hard-codes black, which disappears in the dark theme. */
  .ProseMirror-gapcursor:after {
    border-top-color: currentColor;
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

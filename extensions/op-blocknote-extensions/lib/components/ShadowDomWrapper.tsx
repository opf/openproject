import type { PropsWithChildren } from 'react';
import { createGlobalStyle, StyleSheetManager } from 'styled-components';

interface ShadowDomWrapperProps {
  target:ShadowRoot | HTMLElement;
}

const ProseMirrorBaseStyles = createGlobalStyle`
  .ProseMirror {
    overflow-wrap: break-word;
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

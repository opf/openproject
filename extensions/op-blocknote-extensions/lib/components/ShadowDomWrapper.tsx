import type { PropsWithChildren } from "react";
import { StyleSheetManager } from "styled-components";

interface ShadowDomWrapperProps {
  target: ShadowRoot | HTMLElement;
}

export const ShadowDomWrapper = ({ children, target }: PropsWithChildren<ShadowDomWrapperProps>) => (
  <StyleSheetManager target={target}>
    {children}
  </StyleSheetManager>
);

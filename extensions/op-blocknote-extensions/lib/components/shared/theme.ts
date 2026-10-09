import { css } from 'styled-components';
import { metaTextColor } from '../../services/colors';

export const editorThemeVariables = css`
  --spacer-s: 4px;
  --spacer-m: 8px;
  --spacer-l: 12px;
  --spacer-xl: 16px;
  --spacer-xxl: 20px;

  /* BlockNote's node-selection outline color; not exposed by BlockNote as a variable, so defined here */
  --blocknote-focus-color: rgb(100, 160, 255);

  --lightness-threshold: 0.453;
  --background-alpha: 0.18;

  --op-chip-bg: var(--bgColor-muted, #f6f8fa);
  --op-item-hover-bg: var(--bn-colors-highlights-gray-background, #f0f0f0);
  --op-wp-meta-color: ${metaTextColor};

  [data-color-scheme="dark"] & {
    --lightness-threshold: 0.6;
    --background-alpha: 0.10;
    --op-chip-bg: var(--bgColor-muted, #151b23);
    --op-item-hover-bg: rgba(255, 255, 255, 0.12);
  }
`;

// Shared by work package cards and inline nodes.
export const NODE_CONTENT_GAP = '6px';
export const BLOCK_FOCUS_SHADOW = '0 0 0 4px var(--blocknote-focus-color)';

export const menuSurfaceStyles = css`
  background-color: var(--bn-colors-menu-background, #fff);
  color: var(--bn-colors-menu-text, #3f3f3f);
`;

export const nonSelectableStyles = css`
  -webkit-user-select: none;
  user-select: none;
  -webkit-touch-callout: none;
`;

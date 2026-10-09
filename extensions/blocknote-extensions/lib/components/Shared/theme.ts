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

// A box-shadow, not an outline: OpenProject removes every focus outline inside
// the editor with `outline: none !important`.
export const menuItemFocusStyles = css`
  &:focus-visible {
    box-shadow: inset 0 0 0 2px var(--blocknote-focus-color);
  }
`;

// The -webkit- prefix is not redundant: Safari (including iOS) implements only the prefixed
// property and styled-components v6 no longer auto-prefixes, so unprefixed alone leaves the
// chip text selectable there. Belongs on the container only: `user-select` is not inherited,
// but `auto` on a descendant resolves to `none` under a non-selectable parent.
export const nonSelectableStyles = css`
  -webkit-user-select: none;
  user-select: none;
  -webkit-touch-callout: none;
`;

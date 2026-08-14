import styled, { css, keyframes } from 'styled-components';
import { defaultWpVariables } from '../WorkPackage/atoms';

const surfaceColor = 'var(--op-create-wp-surface)';
const textColor = 'var(--op-create-wp-text)';
const borderColor = 'var(--op-create-wp-border)';
const controlBorderColor = 'var(--op-create-wp-control-border)';
const radius = '6px';
const radiusLarge = '12px';
const arrowsWidth = '32px';

const MODAL_WIDTH = '460px';

export const Overlay = styled.div.attrs({
  className: 'op-bn-create-wp-overlay',
  'data-testid': 'create-wp-overlay',
})`
  ${defaultWpVariables}

  --op-create-wp-shadow: 0 4px 24px rgba(0, 0, 0, 0.08), 0 0 0 1px rgba(0, 0, 0, 0.04);
  --op-create-wp-surface: var(--bgColor-default, #ffffff);
  --op-create-wp-border: var(--borderColor-default, #d1d9e0);
  --op-create-wp-muted: var(--fgColor-muted, #59636e);
  --op-create-wp-danger: var(--fgColor-danger, #d1242f);
  --op-create-wp-link: var(--fgColor-link, #0969da);
  --op-create-wp-text: var(--fgColor-default, #1f2328);
  --op-create-wp-accent: var(--button-primary-bgColor-rest, #1f883d);
  --op-create-wp-accent-hover: var(--button-primary-bgColor-hover, #1c8139);
  --op-create-wp-accent-text: var(--button-primary-fgColor-rest, #ffffff);
  --op-create-wp-disabled: var(--button-primary-bgColor-disabled, #95d8a6);
  --op-create-wp-disabled-text: var(--button-primary-fgColor-disabled, #ffffffcc);
  --op-create-wp-neutral: var(--button-default-bgColor-rest, #f6f8fa);
  --op-create-wp-neutral-hover: var(--button-default-bgColor-hover, #eff2f5);
  --op-create-wp-neutral-border: var(--button-default-borderColor-rest, #d1d9e0);
  --op-create-wp-control-border: var(--control-borderColor-rest, #d1d9e0);
  --op-create-wp-placeholder: var(--control-fgColor-placeholder, #59636e);
  --op-create-wp-arrow: var(--fgColor-muted, #59636e);

  /*  Native widgets (checkbox, date picker, select popup) follow the modal
      rather than the operating system.  */
  color-scheme: light;

  [data-color-scheme="dark"] & {
    --op-create-wp-shadow: 0 4px 28px rgba(0, 0, 0, 0.55), 0 0 0 1px rgba(255, 255, 255, 0.04);
    --op-create-wp-surface: var(--bgColor-default, #0d1117);
    --op-create-wp-border: var(--borderColor-default, #3d444d);
    --op-create-wp-muted: var(--fgColor-muted, #9198a1);
    --op-create-wp-danger: var(--fgColor-danger, #f85149);
    --op-create-wp-link: var(--fgColor-link, #4493f8);
    --op-create-wp-text: var(--fgColor-default, #f0f6fc);
    --op-create-wp-accent: var(--button-primary-bgColor-rest, #238636);
    --op-create-wp-accent-hover: var(--button-primary-bgColor-hover, #29903b);
    --op-create-wp-disabled: var(--button-primary-bgColor-disabled, #105823);
    --op-create-wp-disabled-text: var(--button-primary-fgColor-disabled, #ffffff66);
    --op-create-wp-neutral: var(--button-default-bgColor-rest, #212830);
    --op-create-wp-neutral-hover: var(--button-default-bgColor-hover, #262c36);
    --op-create-wp-neutral-border: var(--button-default-borderColor-rest, #3d444d);
    --op-create-wp-control-border: var(--control-borderColor-rest, #3d444d);
    --op-create-wp-placeholder: var(--control-fgColor-placeholder, #9198a1);
    --op-create-wp-arrow: var(--fgColor-muted, #9198a1);

    color-scheme: dark;
  }

  &, & *, & *::before, & *::after {
    box-sizing: border-box;
  }

  position: fixed;
  inset: 0;
  z-index: 10000;
  display: flex;
  padding: var(--spacer-xl);
  overflow-y: auto;
  overscroll-behavior: contain;
  background: rgba(0, 0, 0, 0.45);
  font-family: var(--bn-font-family, 'SF Pro Text', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif);
  line-height: 1.5;

  @media (max-width: 30rem) {
    padding: var(--spacer-m);
  }
`;

export const Panel = styled.div.attrs({
  className: 'op-bn-create-wp',
  role: 'dialog',
  'aria-modal': true,
  'data-testid': 'create-wp-modal',
})`
  display: flex;
  flex-direction: column;
  /*  Centered by its margins: a centered flex item cannot be scrolled back to
      once it outgrows its container.  */
  margin: auto;
  width: ${MODAL_WIDTH};
  max-width: 100%;
  max-height: 100%;
  overflow: hidden;
  border-radius: ${radiusLarge};
  background: ${surfaceColor};
  box-shadow: var(--op-create-wp-shadow);
  color: ${textColor};
  text-align: left;
  user-select: text;
`;

export const Form = styled.form`
  display: flex;
  flex: 1;
  flex-direction: column;
  min-height: 0;
`;

export const Header = styled.div`
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: var(--spacer-m);
  padding: var(--spacer-m);
  border-bottom: 1px solid ${borderColor};
`;

export const HeaderTitle = styled.span`
  font-size: 1em;
  font-weight: 600;
`;

export const Body = styled.div`
  flex: 1;
  min-height: 0;
  padding: var(--spacer-xl);
  overflow-y: auto;
`;

export const Footer = styled.div`
  display: flex;
  align-items: center;
  justify-content: flex-end;
  gap: var(--spacer-m);
  padding: var(--spacer-m);
  border-top: 1px solid ${borderColor};
`;

export const IconButton = styled.button`
  display: flex;
  align-items: center;
  justify-content: center;
  width: 28px;
  height: 28px;
  padding: 0;
  border: none;
  border-radius: ${radius};
  background: none;
  color: ${textColor};
  cursor: pointer;

  &:hover {
    background: var(--op-item-hover-bg);
  }
`;

export const Button = styled.button<{ $primary?:boolean }>`
  display: inline-flex;
  align-items: center;
  justify-content: center;
  height: 28px;
  padding: 0 var(--spacer-l);
  border-radius: ${radius};
  font-size: 12px;
  font-weight: 600;
  line-height: 1;
  cursor: pointer;

  ${({ $primary }) => ($primary
    ? css`
      border: 1px solid var(--op-create-wp-accent);
      background: var(--op-create-wp-accent);
      color: var(--op-create-wp-accent-text);

      &:hover:not(:disabled) {
        border-color: var(--op-create-wp-accent-hover);
        background: var(--op-create-wp-accent-hover);
      }

      &:disabled {
        border-color: var(--op-create-wp-disabled);
        background: var(--op-create-wp-disabled);
        color: var(--op-create-wp-disabled-text);
      }
    `
    : css`
      border: 1px solid var(--op-create-wp-neutral-border);
      background: var(--op-create-wp-neutral);
      color: ${textColor};

      &:hover {
        background: var(--op-create-wp-neutral-hover);
      }
    `)}

  &:disabled {
    cursor: not-allowed;
  }
`;

const fieldIn = keyframes`
  from { opacity: 0; transform: translateY(-4px); }
  to { opacity: 1; transform: translateY(0); }
`;

export const FieldRow = styled.div<{ $invalid?:boolean }>`
  margin-bottom: var(--spacer-xl);
  animation: ${fieldIn} 0.18s ease;

  /*  Tripled: the controls carry their own doubled rules, ":focus" among them.  */
  ${({ $invalid }) => $invalid && css`
    &&& input, &&& select, &&& textarea {
      border-color: var(--op-create-wp-danger);
    }
  `}
`;

export const Divider = styled.hr`
  && {
    margin: 0 0 var(--spacer-xl);
    border: none;
    border-top: 1px solid ${borderColor};
  }
`;

export const FieldError = styled.div.attrs({ role: 'alert' })`
  margin-top: var(--spacer-s);
  font-size: 0.85em;
  color: var(--op-create-wp-danger);
`;

export const FieldLabel = styled.label`
  display: block;
  margin-bottom: var(--spacer-s);
  font-size: 14px;
  font-weight: 600;
  color: ${textColor};
`;

export const RequiredMark = styled.span`
  font-size: 14px;
  font-weight: 600;
  color: ${textColor};
`;

/*  Doubled: OpenProject styles inputs by their type ("input[type=text]"), which
    outweighs a single class.  */
const controlStyles = css`
  && {
    box-sizing: border-box;
    width: 100%;
    height: auto;
    padding: var(--spacer-m) var(--spacer-l);
    border: 1px solid ${controlBorderColor};
    border-radius: ${radius};
    background: ${surfaceColor};
    color: ${textColor};
    font-family: inherit;
    font-size: 14px;
    font-weight: 400;
    line-height: 1.4;

    &:focus {
      border-color: ${controlBorderColor};
    }

    &::placeholder {
      color: var(--op-create-wp-placeholder);
      font-size: 14px;
      font-weight: 400;
    }

    &:focus::placeholder {
      opacity: 0;
    }
  }
`;

export const TextControl = styled.input`
  ${controlStyles}
`;

export const TextAreaControl = styled.textarea`
  ${controlStyles}
  min-height: 72px;
  resize: vertical;
`;

export const SelectControl = styled.select`
  ${controlStyles}
  appearance: none;
  cursor: pointer;

  && {
    padding-right: ${arrowsWidth};
  }

  /*  OpenProject paints its own arrow onto every select with !important.  */
  && {
    background-image: none !important;
  }
`;

export const SelectWrapper = styled.div`
  position: relative;
  display: flex;
  align-items: center;
`;

export const CheckboxRow = styled.label`
  display: flex;
  align-items: center;
  gap: var(--spacer-m);
  font-size: 0.9em;
  cursor: pointer;
`;

export const Notice = styled.div<{ $error?:boolean }>`
  display: flex;
  align-items: flex-start;
  gap: var(--spacer-m);
  margin-bottom: var(--spacer-l);
  padding: var(--spacer-m) var(--spacer-l);
  border-radius: ${radius};
  background: var(--op-item-hover-bg);
  font-size: 0.85em;
  color: ${({ $error }) => ($error ? 'var(--op-create-wp-danger)' : textColor)};

  svg {
    flex-shrink: 0;
    margin-top: 2px;
  }
`;

export const NoticeLink = styled.a`
  color: var(--op-create-wp-link);
`;

const spin = keyframes`
  to { transform: rotate(360deg); }
`;

export const Spinner = styled.span`
  display: inline-flex;
  animation: ${spin} 0.9s linear infinite;
`;

export const LoadingRow = styled.div`
  display: flex;
  align-items: center;
  gap: var(--spacer-m);
  padding-bottom: var(--spacer-xl);
  font-size: 0.85em;
  color: var(--op-create-wp-muted);
`;

export const SuggestionList = styled.div.attrs({ role: 'listbox' })`
  position: fixed;
  z-index: 1;
  overflow-y: auto;
  padding: var(--spacer-s);
  border: 1px solid ${controlBorderColor};
  border-radius: ${radius};
  background: ${surfaceColor};
  box-shadow: var(--op-create-wp-shadow);
`;

export const SuggestionItem = styled.div.attrs({ role: 'option' })<{ $focused:boolean }>`
  padding: var(--spacer-m) var(--spacer-l);
  border-radius: ${radius};
  font-size: 0.9em;
  cursor: pointer;
  background: ${({ $focused }) => ($focused ? 'var(--op-item-hover-bg)' : 'transparent')};

  &:hover {
    background: var(--op-item-hover-bg);
  }
`;

export const SuggestionEmpty = styled.div`
  padding: var(--spacer-m) var(--spacer-l);
  font-size: 0.85em;
  color: var(--op-create-wp-muted);
`;

export const TypeaheadWrapper = styled.div<{ $withArrows?:boolean }>`
  position: relative;
  display: flex;
  align-items: center;

  ${({ $withArrows }) => $withArrows && css`
    && input {
      padding-right: ${arrowsWidth};
    }
  `}
`;

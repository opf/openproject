import styled, { css, keyframes } from 'styled-components';
import { defaultWpVariables } from '../WorkPackage/atoms';
import { defaultColorStyles, typeTextColor } from '../../services/colors';

const surfaceColor = 'var(--op-create-wp-surface)';
const textColor = 'var(--op-create-wp-text)';
const borderColor = 'var(--op-create-wp-border)';
const controlBorderColor = 'var(--op-create-wp-control-border)';
const radiusSmall = '4px';
const radius = '6px';
const radiusLarge = '12px';
const colorDotSize = '12px';
const colorDotWidth = `calc(var(--spacer-l) + ${colorDotSize} + var(--spacer-m))`;

const indentStep = 14;

export const ACTION_ICON_SIZE = 14;

const actionSize = '20px';
const actionsGap = 'var(--spacer-s)';
const actionsInset = 'calc(var(--spacer-l) - 4px)';

const roomForActions = (actions:number) => `calc(${actionsInset} + ${actions} * ${actionSize}`
  + ` + ${actions - 1} * ${actionsGap} + var(--spacer-s))`;

const actionStyles = css`
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
  width: ${actionSize};
  height: ${actionSize};
  padding: 0;
  border: none;
  border-radius: ${radiusSmall};
  background: none;
  line-height: 0;
  cursor: pointer;
  transition: background-color 0.2s cubic-bezier(0.3, 0, 0.5, 1);
`;

const rowMarkInset = 'var(--spacer-s)';

const rowMarkHover = css`
  position: relative;
  align-self: stretch;
  height: auto;
  margin-top: calc(-1 * var(--spacer-m));
  margin-bottom: calc(-1 * var(--spacer-m));

  /*  Above the block, which is drawn after it.  */
  & > svg {
    position: relative;
    z-index: 1;
  }

  &::before {
    content: '';
    position: absolute;
    top: 0;
    bottom: 0;
    left: calc(-1 * ${rowMarkInset});
    right: calc(-1 * ${rowMarkInset});
    border-radius: ${radiusSmall};
    transition: background-color 0.2s cubic-bezier(0.3, 0, 0.5, 1);
  }

  &:hover::before {
    background: var(--op-create-wp-action-hover);
  }
`;

const MODAL_WIDTH = '460px';
const MODAL_TOP_OFFSET = 'min(10vh, 4rem)';

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
  --op-create-wp-action-hover: var(--control-transparent-bgColor-hover, rgba(129, 139, 152, 0.15));
  --op-create-wp-line: var(--borderColor-muted, rgba(209, 217, 224, 0.7));
  --op-create-wp-selected-bg: var(--control-transparent-bgColor-selected, rgba(129, 139, 152, 0.24));

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
    --op-create-wp-action-hover: var(--control-transparent-bgColor-hover, rgba(177, 186, 196, 0.15));
    --op-create-wp-line: var(--borderColor-muted, rgba(61, 68, 77, 0.7));
    --op-create-wp-selected-bg: var(--control-transparent-bgColor-selected, rgba(177, 186, 196, 0.24));

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
  /*  Not centered: the fields arrive in groups, and centering moves the ones
      already shown on every arrival. Margins rather than alignment, so the
      panel can still be scrolled to once it outgrows its container.  */
  margin: ${MODAL_TOP_OFFSET} auto auto;
  width: ${MODAL_WIDTH};
  max-width: 100%;
  max-height: calc(100% - ${MODAL_TOP_OFFSET});
  overflow: hidden;
  /*  Focused only to catch the keys before the first field exists, so it takes
      no focus ring of its own.  */
  outline: none;
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

export const PickerControl = styled(TextControl)<{ $namesPick?:boolean }>`
  ${({ $namesPick }) => $namesPick && css`
    &&&:focus::placeholder {
      opacity: 1;
    }
  `}
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
    padding-right: ${roomForActions(1)};
  }

  /*  OpenProject paints its own arrow onto every select with !important.  */
  && {
    background-image: none !important;
  }
`;

export const SelectWrapper = styled.div<{ $withColorDot?:boolean }>`
  position: relative;
  display: flex;
  align-items: center;

  ${({ $withColorDot }) => $withColorDot && css`
    && select {
      padding-left: ${colorDotWidth};
    }
  `}
`;

export const TypeColorDot = styled.span.attrs({
  className: 'op-bn-create-wp-type-color',
  'data-testid': 'create-wp-type-color',
})<{ $color:string }>`
  ${({ $color }) => defaultColorStyles($color)}
  position: absolute;
  left: var(--spacer-l);
  width: ${colorDotSize};
  height: ${colorDotSize};
  border-radius: 50%;
  background: ${typeTextColor};
  pointer-events: none;
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

export const LoadingRow = styled.div<{ $reserveHeight?:boolean }>`
  display: flex;
  align-items: center;
  gap: var(--spacer-m);
  padding-bottom: var(--spacer-xl);
  font-size: 0.85em;
  color: var(--op-create-wp-muted);

  /*  Stands in for the fields still loading, holding part of their height.  */
  ${({ $reserveHeight }) => $reserveHeight && css`
    justify-content: center;
    min-height: 12rem;
    padding-bottom: 0;
  `}
`;

export const SuggestionList = styled.div`
  position: fixed;
  z-index: 1;
  overflow-y: auto;
  padding: 0 var(--spacer-s) var(--spacer-s);
  border: 1px solid ${controlBorderColor};
  border-radius: ${radius};
  background: ${surfaceColor};
  box-shadow: var(--op-create-wp-shadow);
`;

export const SuggestionItem = styled.div<{ $focused:boolean; $selected?:boolean }>`
  display: flex;
  align-items: center;
  gap: var(--spacer-s);
  /*  The indent is drawn by the level lines rather than by padding, so that
      they run from row to row without a gap.  */
  padding: var(--spacer-m) ${rowMarkInset};
  border-radius: ${radius};
  font-size: 0.9em;
  cursor: pointer;
  /*  The picked one stays marked wherever the focus wanders, as OpenProject
      keeps the current project marked, and deeper than what is merely hovered.  */
  background: ${({ $focused, $selected }) => {
    if ($selected) return 'var(--op-create-wp-selected-bg)';
    return $focused ? 'var(--op-item-hover-bg)' : 'transparent';
  }};

  &:hover {
    background: ${({ $selected }) => ($selected ? 'var(--op-create-wp-selected-bg)' : 'var(--op-item-hover-bg)')};
  }
`;

export const SuggestionLabel = styled.span`
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
`;

/*  Pushed to the right end of the row, where OpenProject puts it too.  */
export const RowAction = styled.button.attrs({ type: 'button', tabIndex: -1 })`
  && {
    ${actionStyles}
    ${rowMarkHover}
    margin-left: auto;
    background: none;
    color: var(--op-create-wp-muted);
  }
`;

/*  Behind the name, as OpenProject marks a favorite everywhere else.  */
export const FavoredMark = styled.span`
  display: inline-flex;
  flex-shrink: 0;
  line-height: 0;
  color: var(--button-star-iconColor, #eac54f);
`;

/*  Held above the options so the filters stay reachable however far the list
    scrolls. Over the marks of a row too, which lift themselves over their own
    row to answer the pointer.  */
export const SuggestionHeader = styled.div`
  position: sticky;
  top: 0;
  z-index: 2;
  display: flex;
  align-items: center;
  gap: var(--spacer-m);
  /*  Bled over the list's side padding, so its rule spans the whole popover.  */
  margin: 0 calc(-1 * var(--spacer-s));
  padding: var(--spacer-m);
  border-bottom: 1px solid ${borderColor};
  background: ${surfaceColor};
`;

export const FilterModes = styled.div.attrs({ role: 'group' })`
  display: flex;
  flex-shrink: 0;
`;

export const FilterMode = styled.button.attrs({ type: 'button' })<{ $active:boolean }>`
  && {
    padding: 3px var(--spacer-l);
    border: 1px solid ${({ $active }) => ($active ? controlBorderColor : 'transparent')};
    border-radius: ${radius};
    background: ${({ $active }) => ($active ? 'var(--op-create-wp-neutral)' : 'transparent')};
    color: ${({ $active }) => ($active ? textColor : 'var(--op-create-wp-muted)')};
    font-family: inherit;
    font-size: 12px;
    font-weight: ${({ $active }) => ($active ? 600 : 400)};
    line-height: 1.4;
    cursor: pointer;
  }

  &&:hover {
    color: ${textColor};
  }
`;

/*  One per level the row sits in, as OpenProject draws them: an indent as wide
    as the fold marker, closed by the line that ties a subtree together. Stretched
    past the row's own padding so the lines of neighbouring rows meet.  */
export const LevelLine = styled.span`
  position: relative;
  flex-shrink: 0;
  align-self: stretch;
  width: ${indentStep}px;
  margin-top: calc(-1 * var(--spacer-m));
  margin-bottom: calc(-1 * var(--spacer-m));

  &::before {
    content: '';
    position: absolute;
    top: 0;
    bottom: 0;
    left: 50%;
    width: 1px;
    transform: translateX(-50%);
    background: var(--op-create-wp-line);
    transition: opacity 0.15s ease;
  }
`;

export const SuggestionTree = styled.div`
  padding-top: var(--spacer-s);

  @media (hover: hover) {
    ${LevelLine}::before {
      opacity: 0;
    }

    &:hover ${LevelLine}::before {
      opacity: 1;
    }
  }
`;

/*  A slot of its own, so the labels of a level line up whether or not the row
    can be unfolded.  */
export const Twisty = styled.span<{ $foldable?:boolean; $indent?:number }>`
  display: inline-flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
  width: ${indentStep}px;
  height: ${indentStep}px;
  margin-right: var(--spacer-s);
  line-height: 0;
  color: var(--op-create-wp-muted);

  ${({ $foldable, $indent = 0 }) => $foldable && css`
    cursor: pointer;
    ${rowMarkHover}

    &::after {
      content: '';
      position: absolute;
      top: 0;
      bottom: 0;
      right: calc(-1 * ${rowMarkInset});
      left: calc(-1 * (${rowMarkInset} + ${$indent} * (${indentStep}px + var(--spacer-s))));
    }
  `}
`;

export const SuggestionEmpty = styled.div`
  padding: var(--spacer-m) var(--spacer-l);
  font-size: 0.85em;
  color: var(--op-create-wp-muted);
`;

/*  Sized here rather than on the field: the popover is not portalled out of it.  */
export const TypeaheadWrapper = styled.div<{ $actions?:number }>`
  position: relative;
  display: flex;
  align-items: center;

  && > input {
    padding-right: ${({ $actions = 1 }) => roomForActions($actions)};
  }
`;

export const TrailingActions = styled.span`
  position: absolute;
  right: ${actionsInset};
  display: flex;
  align-items: center;
  gap: ${actionsGap};
`;

/*  Doubled, as OpenProject styles every button of its own. Only the background
    answers the pointer, as it does on every trailing action of Primer's.  */
export const TrailingButton = styled.button.attrs({ type: 'button', tabIndex: -1 })`
  && {
    ${actionStyles}
    color: var(--op-create-wp-arrow);
  }

  &&:hover {
    background: var(--op-create-wp-action-hover);
  }
`;

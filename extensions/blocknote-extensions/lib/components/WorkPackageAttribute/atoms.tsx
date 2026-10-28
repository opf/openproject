import styled, { css } from 'styled-components';
import { CHIP_STYLES } from '../WorkPackage/tokens';
import { defaultWpVariables, nonSelectableStyles } from '../WorkPackage/atoms';
import { FieldLabel, Panel, PickerControl } from '../CreateWorkPackage/atoms';

// Drawn inward, so that it adds nothing to the height.
const ATTRIBUTE_BORDER = 'inset 0 0 0 1px var(--borderColor-default, #d1d9e0)';
const ATTRIBUTE_TEXT_SIZE = '14px';

export const MutedText = styled.span`
  color: var(--op-wp-meta-color);
`;

export const AttributeChipSurface = styled.span.attrs({
  className: 'op-bn-wp-attribute',
})`
  ${defaultWpVariables}
  ${nonSelectableStyles}
  display: inline;
  padding: ${CHIP_STYLES.padding.s};
  border-radius: ${CHIP_STYLES.radius};
  box-shadow: ${ATTRIBUTE_BORDER};
  background: var(--bn-colors-editor-background, #ffffff);
  color: var(--bn-colors-editor-text);
  /*  Sized like an inline work package: the box from the small font, the text set larger inside.  */
  font-size: ${CHIP_STYLES.fontSize};
  box-decoration-break: clone;
  -webkit-box-decoration-break: clone;
  overflow-wrap: anywhere;

  ${MutedText} {
    font-size: ${ATTRIBUTE_TEXT_SIZE};
  }
`;

export const AttributeChip = styled(AttributeChipSurface).attrs({ contentEditable: false })<{ $selected:boolean }>`
  position: relative;
  cursor: pointer;
  box-shadow: ${({ $selected }) => ($selected ? CHIP_STYLES.inlineFocusShadow : ATTRIBUTE_BORDER)};
`;

export const AttributeLabelText = styled.span`
  font-size: ${ATTRIBUTE_TEXT_SIZE};
  font-weight: 600;
`;

export const AttributeValueText = styled.span`
  font-size: ${ATTRIBUTE_TEXT_SIZE};
`;

export const AttributeFieldLabel = styled(FieldLabel)<{ $disabled:boolean }>`
  color: ${({ $disabled }) => ($disabled ? 'var(--op-create-wp-muted)' : 'var(--op-create-wp-text)')};
`;

// Tripled to outweigh the doubled rules the control shares with the form.
export const DisabledControl = styled(PickerControl)`
  &&&:disabled {
    background: var(--op-create-wp-neutral);
    color: var(--op-create-wp-muted);
    cursor: not-allowed;
    opacity: 1;
  }
`;

// The create form's frame with an accent instead of a success colored action.
export const AttributePanel = styled(Panel)`
  --op-create-wp-accent: var(--bgColor-accent-emphasis, #0969da);
  --op-create-wp-accent-hover: color-mix(in srgb, var(--op-create-wp-accent) 88%, black);
  --op-create-wp-disabled: var(--bgColor-disabled, #eff2f5);
  --op-create-wp-disabled-text: var(--fgColor-disabled, #818b98);

  [data-color-scheme="dark"] & {
    --op-create-wp-accent: var(--bgColor-accent-emphasis, #1f6feb);
    --op-create-wp-disabled: var(--bgColor-disabled, #212830);
    --op-create-wp-disabled-text: var(--fgColor-disabled, #656c76);
  }
`;

// Doubled to drop the button chrome OpenProject gives every button.
export const LinkButton = styled.button.attrs({ type: 'button' })`
  && {
    padding: 0;
    border: none;
    background: none;
    color: var(--op-create-wp-link);
    font: inherit;
    cursor: pointer;
  }

  &&:hover {
    text-decoration: underline;
  }
`;

export const PrefillNote = styled.div`
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: var(--spacer-m);
  margin-bottom: var(--spacer-l);
  font-size: 13px;
  color: var(--op-create-wp-muted);

  & > span {
    display: flex;
    align-items: center;
    gap: var(--spacer-s);
  }
`;

export const DisplayOptions = styled.div.attrs({ role: 'radiogroup' })`
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 2px;
  padding: 3px;
  border-radius: var(--bn-border-radius-medium, 8px);
  background: var(--op-create-wp-neutral);
`;

export const DisplayOption = styled.button.attrs({ type: 'button', role: 'radio' })<{ $active:boolean }>`
  && {
    padding: 6px var(--spacer-m);
    border: 1px solid ${({ $active }) => ($active ? 'var(--op-create-wp-control-border)' : 'transparent')};
    border-radius: var(--bn-border-radius-small, 6px);
    background: ${({ $active }) => ($active ? 'var(--op-create-wp-surface)' : 'transparent')};
    color: ${({ $active }) => ($active ? 'var(--op-create-wp-text)' : 'var(--op-create-wp-muted)')};
    font-family: inherit;
    font-size: 13px;
    font-weight: ${({ $active }) => ($active ? 600 : 500)};
    cursor: pointer;
  }
`;

export const PreviewLabel = styled.div`
  margin-bottom: var(--spacer-s);
  font-size: 12px;
  color: var(--op-create-wp-muted);
`;

export const PreviewBox = styled.div`
  min-height: 44px;
  line-height: 1.6;
  overflow-wrap: anywhere;
  padding: var(--spacer-m) var(--spacer-l);
  border: 1px solid var(--op-create-wp-border);
  border-radius: var(--bn-border-radius-small, 6px);
  background: var(--op-create-wp-neutral);
  font-size: 14px;
`;

export const PreviewPlaceholder = styled.span`
  color: var(--op-create-wp-placeholder);
  font-size: 13px;
`;

// Kept whole: the subject next to it is what gives way.
export const WorkPackageReference = styled.span`
  display: inline-flex;
  align-items: center;
  gap: var(--spacer-m);
  flex-shrink: 0;
  white-space: nowrap;
`;

// Drawn over the empty field: a plain input cannot color the type.
export const SelectedWorkPackage = styled.span`
  position: absolute;
  inset: 0 calc(var(--spacer-l) + 28px) 0 calc(var(--spacer-l) + 1px);
  display: flex;
  align-items: center;
  overflow: hidden;
  pointer-events: none;
  font-size: 14px;
  color: var(--op-create-wp-text);
`;

// Marked like selected text while focused: typing replaces it.
export const SelectedText = styled.span<{ $marked:boolean }>`
  display: inline-flex;
  align-items: center;
  gap: var(--spacer-m);
  min-width: 0;
  max-width: 100%;

  ${({ $marked }) => $marked && css`
    background: Highlight;

    &, & * {
      color: HighlightText !important;
    }
  `}
`;

export const SelectedSubject = styled.span`
  min-width: 0;
  overflow: hidden;
  white-space: nowrap;
  text-overflow: ellipsis;
`;

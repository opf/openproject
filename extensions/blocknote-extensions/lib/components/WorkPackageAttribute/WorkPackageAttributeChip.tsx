import { useRef, useState } from 'react';
import styled from 'styled-components';
import { useTranslation } from 'react-i18next';
import type { BlockNoteEditor } from '@blocknote/core';
import { CHIP_STYLES } from '../WorkPackage/tokens';
import { defaultWpVariables, nonSelectableStyles } from '../WorkPackage/atoms';
import { formatWorkPackageId } from '../../utils/id';
import { useTapActivation } from '../../utils/tapActivation';
import { useSuppressFormattingToolbar } from '../../hooks/useSuppressFormattingToolbar';
import { usePressOutside } from '../../hooks/usePressOutside';
import { PENDING_PREFIX } from '../InlineWorkPackage/callbacks';
import { normalizeDisplay, type AttributeDisplay } from './externalHtml';
import { useWorkPackageAttribute, type ResolvedAttribute } from './useWorkPackageAttribute';
import { getPendingAttribute } from './pending';
import { lastAttributeChoice, rememberAttributeChoice } from './lastChoice';
import { InsertAttributeModal } from './InsertAttributeModal';
import { AttributeDisplayMenu } from './AttributeDisplayMenu';

export const AttributeChipSurface = styled.span.attrs({
  className: 'op-bn-wp-attribute',
})`
  ${defaultWpVariables}
  ${nonSelectableStyles}
  /*  Tinted, unlike work package chips: it reads as a value, not a link.  */
  --op-attribute-chip-bg: var(--bgColor-accent-muted, #ddf4ff);

  [data-color-scheme="dark"] & {
    --op-attribute-chip-bg: var(--bgColor-accent-muted, rgba(56, 139, 253, 0.1));
  }

  display: inline;
  padding: ${CHIP_STYLES.padding.s};
  border-radius: ${CHIP_STYLES.radius};
  background: var(--op-attribute-chip-bg);
  box-decoration-break: clone;
  -webkit-box-decoration-break: clone;
  overflow-wrap: anywhere;
`;

const Chip = styled(AttributeChipSurface).attrs({ contentEditable: false })<{ $selected:boolean }>`
  position: relative;
  cursor: pointer;
  box-shadow: ${({ $selected }) => ($selected ? CHIP_STYLES.inlineFocusShadow : 'none')};
`;

const Label = styled.span<{ $muted:boolean }>`
  color: ${({ $muted }) => ($muted ? 'var(--op-wp-meta-color)' : 'var(--bn-colors-highlights-blue-text)')};
`;

const Value = styled.span`
  color: var(--bn-colors-highlights-blue-text);
  font-weight: 500;
`;

const Muted = styled.span`
  color: var(--op-wp-meta-color);
`;

export function WorkPackageAttributeView({ resolved, display, reference }:{
  resolved:ResolvedAttribute,
  display:string,
  reference:string,
}) {
  const { t } = useTranslation();

  if (resolved.state !== 'ready') {
    if (resolved.state === 'loading') return <Muted>{reference}…</Muted>;
    if (resolved.state === 'missing') return <Muted>{t('workPackageAttribute.missing', { attribute: reference })}</Muted>;
    return <Muted>{t(`unavailableWorkPackage.${resolved.state}.short_message`)}</Muted>;
  }

  const shown = normalizeDisplay(display);
  if (shown === 'label') return <Label $muted={false}>{resolved.attribute.label}</Label>;
  if (shown === 'value') return <Value>{resolved.value}</Value>;
  return (
    <>
      <Label $muted>{resolved.attribute.label}: </Label>
      <Value>{resolved.value}</Value>
    </>
  );
}

interface AttributeProps {
  wpid:string;
  displayId:string;
  attribute:string;
  display:string;
}

export interface WorkPackageAttributeChipProps {
  props:AttributeProps;
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  editor?:BlockNoteEditor<any, any, any>;
  contentRef?:(node:HTMLElement | null) => void;
  onDisplayChange?:(display:AttributeDisplay) => void;
}

function ResolvedAttributeChip({ props, editor, contentRef, onDisplayChange }:WorkPackageAttributeChipProps) {
  const { wpid, displayId, attribute, display } = props;
  const resolved = useWorkPackageAttribute(wpid, attribute);
  const chipRef = useRef<HTMLElement | null>(null);
  const [menuOpen, setMenuOpen] = useState(false);
  const tapProps = useTapActivation();
  useSuppressFormattingToolbar(editor, menuOpen);

  usePressOutside(chipRef, menuOpen, () => setMenuOpen(false));

  const title = resolved.state === 'ready'
    ? `${formatWorkPackageId(resolved.workPackage.displayId)} · ${resolved.workPackage.subject}`
    : formatWorkPackageId(displayId);

  return (
    <Chip
      ref={(node:HTMLElement | null) => {
        chipRef.current = node;
        contentRef?.(node);
      }}
      title={title}
      role="button"
      aria-haspopup="menu"
      aria-expanded={menuOpen}
      $selected={menuOpen}
      data-drag-handle
      {...tapProps((event) => {
        event?.preventDefault();
        event?.stopPropagation();
        setMenuOpen((open) => !open);
      })}
    >
      <WorkPackageAttributeView resolved={resolved} display={display} reference={attribute} />
      {menuOpen && onDisplayChange && (
        <AttributeDisplayMenu
          // eslint-disable-next-line react-hooks/refs
          anchorEl={chipRef.current}
          active={normalizeDisplay(display)}
          onPick={(picked) => {
            setMenuOpen(false);
            if (picked !== normalizeDisplay(display)) onDisplayChange(picked);
          }}
        />
      )}
    </Chip>
  );
}

export function WorkPackageAttributeChip({ props, editor, contentRef, onDisplayChange }:WorkPackageAttributeChipProps) {
  const [anchorEl, setAnchorEl] = useState<HTMLElement | null>(null);
  const pending = getPendingAttribute(props.wpid);

  if (pending) {
    return (
      <Chip
        $selected={false}
        ref={(node:HTMLElement | null) => {
          setAnchorEl(node);
          contentRef?.(node);
        }}
      >
        {anchorEl && (
          <InsertAttributeModal
            anchorEl={anchorEl}
            prefill={lastAttributeChoice()}
            onInsert={(choice) => {
              rememberAttributeChoice(choice);
              pending.onInsert(choice);
            }}
            onCancel={pending.onCancel}
          />
        )}
      </Chip>
    );
  }

  // Another collaborator's dialog is still open on it.
  if (props.wpid.startsWith(PENDING_PREFIX)) return <span ref={contentRef} />;

  return <ResolvedAttributeChip props={props} editor={editor} contentRef={contentRef} onDisplayChange={onDisplayChange} />;
}

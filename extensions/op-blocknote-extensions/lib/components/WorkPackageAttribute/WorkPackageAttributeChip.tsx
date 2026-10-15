import { useRef, useState } from 'react';
import type { BlockNoteEditor } from '@blocknote/core';
import { formatWorkPackageId } from '../../utils/id';
import { useTapActivation } from '../../utils/tapActivation';
import { useSuppressFormattingToolbar } from '../../hooks/useSuppressFormattingToolbar';
import { usePressOutside } from '../../hooks/usePressOutside';
import { PENDING_PREFIX } from '../InlineWorkPackage/callbacks';
import { normalizeDisplay, type AttributeDisplay } from './externalHtml';
import { useWorkPackageAttribute } from './useWorkPackageAttribute';
import { getPendingAttribute } from './pending';
import { lastAttributeChoice, rememberAttributeChoice } from './lastChoice';
import { InsertAttributeModal } from './InsertAttributeModal';
import { AttributeDisplayMenu } from './AttributeDisplayMenu';
import { AttributeChip } from './atoms';
import { WorkPackageAttributeView } from './WorkPackageAttributeView';

interface AttributeProps {
  wpid:string;
  displayId:string;
  attribute:string;
  display:string;
}

interface WorkPackageAttributeChipProps {
  content:AttributeProps;
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  editor?:BlockNoteEditor<any, any, any>;
  contentRef?:(node:HTMLElement | null) => void;
  onDisplayChange?:(display:AttributeDisplay) => void;
}

function ResolvedAttributeChip({ content, editor, contentRef, onDisplayChange }:WorkPackageAttributeChipProps) {
  const { wpid, displayId, attribute, display } = content;
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
    <AttributeChip
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
    </AttributeChip>
  );
}

export function WorkPackageAttributeChip({ content, editor, contentRef, onDisplayChange }:WorkPackageAttributeChipProps) {
  const [anchorEl, setAnchorEl] = useState<HTMLElement | null>(null);
  const pending = getPendingAttribute(content.wpid);

  if (pending) {
    return (
      <AttributeChip
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
      </AttributeChip>
    );
  }

  // Another collaborator's dialog is still open on it.
  if (content.wpid.startsWith(PENDING_PREFIX)) return <span ref={contentRef} />;

  return <ResolvedAttributeChip content={content} editor={editor} contentRef={contentRef} onDisplayChange={onDisplayChange} />;
}

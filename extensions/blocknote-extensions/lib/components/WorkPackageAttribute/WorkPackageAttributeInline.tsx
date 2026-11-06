import { useRef, useState } from 'react';
import type { BlockNoteEditor } from '@blocknote/core';
import { formatWorkPackageId } from '../../utils/id';
import { useTapActivation } from '../../utils/tapActivation';
import { useSuppressFormattingToolbar } from '../../hooks/useSuppressFormattingToolbar';
import { usePressOutside } from '../../hooks/usePressOutside';
import { isPendingWpid } from '../../utils/pending';
import { normalizeDisplay, type AttributeDisplay } from './externalHtml';
import { useWorkPackageAttribute } from './useWorkPackageAttribute';
import { pendingAttributes } from './pending';
import { lastChoice, rememberChoice } from './lastChoice';
import { InsertAttributeModal } from './InsertAttributeModal';
import { AttributeDisplayMenu } from './AttributeDisplayMenu';
import { AttributeInline } from './atoms';
import { WorkPackageAttributeView } from './WorkPackageAttributeView';

interface AttributeProps {
  wpid:string;
  displayId:string;
  attribute:string;
  display:string;
}

interface WorkPackageAttributeInlineProps {
  content:AttributeProps;
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  editor?:BlockNoteEditor<any, any, any>;
  contentRef?:(node:HTMLElement | null) => void;
  onDisplayChange?:(display:AttributeDisplay) => void;
}

function ResolvedAttributeInline({ content, editor, contentRef, onDisplayChange }:WorkPackageAttributeInlineProps) {
  const { wpid, displayId, attribute, display } = content;
  const resolved = useWorkPackageAttribute(wpid, attribute);
  const attributeRef = useRef<HTMLElement | null>(null);
  const [menuOpen, setMenuOpen] = useState(false);
  const tapProps = useTapActivation();
  useSuppressFormattingToolbar(editor, menuOpen);

  usePressOutside(attributeRef, menuOpen, () => setMenuOpen(false));

  const title = resolved.state === 'ready'
    ? `${formatWorkPackageId(resolved.workPackage.displayId)} · ${resolved.workPackage.subject}`
    : formatWorkPackageId(displayId);

  return (
    <AttributeInline
      ref={(node:HTMLElement | null) => {
        attributeRef.current = node;
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
          anchorEl={attributeRef.current}
          active={normalizeDisplay(display)}
          onPick={(picked) => {
            setMenuOpen(false);
            if (picked !== normalizeDisplay(display)) onDisplayChange(picked);
          }}
        />
      )}
    </AttributeInline>
  );
}

export function WorkPackageAttributeInline({ content, editor, contentRef, onDisplayChange }:WorkPackageAttributeInlineProps) {
  const [anchorEl, setAnchorEl] = useState<HTMLElement | null>(null);
  const pending = pendingAttributes.get(content.wpid);

  if (pending) {
    return (
      <AttributeInline
        $selected={false}
        ref={(node:HTMLElement | null) => {
          setAnchorEl(node);
          contentRef?.(node);
        }}
      >
        {anchorEl && (
          <InsertAttributeModal
            anchorEl={anchorEl}
            prefill={lastChoice()}
            onInsert={(choice) => {
              rememberChoice(choice);
              pending.onResolve(choice);
            }}
            onCancel={pending.onCancel}
          />
        )}
      </AttributeInline>
    );
  }

  // Another collaborator's dialog is still open on it.
  if (isPendingWpid(content.wpid)) return <span ref={contentRef} />;

  return <ResolvedAttributeInline content={content} editor={editor} contentRef={contentRef} onDisplayChange={onDisplayChange} />;
}

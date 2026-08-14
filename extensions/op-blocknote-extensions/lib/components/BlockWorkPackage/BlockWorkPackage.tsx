import type { BlockNoteEditor, SideMenuExtension } from '@blocknote/core';
import { useSelectedBlocks } from '@blocknote/react';
import { useEffect, useRef, useState } from 'react';
import styled from 'styled-components';
import { useTranslation } from 'react-i18next';
import { useWorkPackage } from '../../hooks/useWorkPackage';
import { useColors } from '../../services/colors';
import { convertBlockToInlineChip } from '../../utils/inlineChipActions';
import type { WorkPackage } from '../../openProjectTypes';
import type { InlineWpSize, BlockWpSize } from '../WorkPackage/types';
import type { BlockWorkPackageProps } from './types';
import { EyeClosedIcon, AlertIcon } from '@primer/octicons-react';
import { BlockCard } from './BlockCard';
import { UnavailableCard } from '../WorkPackage/UnavailableCard';
import { WpOptionsPopover } from '../WorkPackage/OptionsPopover';
import { SearchContainer, SearchLabel } from '../Search/SearchContainer';
import { SearchDropdown } from '../Search/SearchDropdown';
import { CreateWorkPackageModal } from '../CreateWorkPackage';
import { defaultWpVariables, nonSelectableStyles } from '../WorkPackage/atoms';
import { CHIP_STYLES } from '../WorkPackage/tokens';
import { moveCursorAfterBlock } from '../../utils/cursor';
import { hideSafariPhantomSelection } from '../../utils/selection';
import { pendingBlockRegistry } from './pendingBlockRegistry';
import { useSuppressFormattingToolbar } from '../../hooks/useSuppressFormattingToolbar';

const Block = styled.div.attrs({ className: 'op-bn-extensions', 'data-testid': 'block-wp-wrapper' })<{ $pending?:boolean; $selected?:boolean }>`
  ${defaultWpVariables}
  background-color: ${({ $pending }) => ($pending ? 'transparent' : 'var(--op-chip-bg)')};
  ${nonSelectableStyles}
  border-radius: var(--bn-border-radius);
  box-shadow: ${({ $selected }) => ($selected ? CHIP_STYLES.focusShadow : 'none')};
  ${({ $pending }) => $pending && 'position: relative;'}
`;

const BlockCardWrapper = styled.div`
  position: relative;
  display: inline-block;
`;

const UnavailableCardWrapper = styled(BlockCardWrapper)`
  display: block;
  cursor: pointer;
`;

type SideMenuInstance = NonNullable<ReturnType<ReturnType<typeof SideMenuExtension>>>;

interface BlockProps {
  id:string;
  props:BlockWorkPackageProps;
}

export const BlockWorkPackageComponent = ({
  block,
  editor,
}:{
  block:BlockProps;
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  editor:BlockNoteEditor<any>;
}) => {
  const { t } = useTranslation();
  const cardRef = useRef<HTMLDivElement>(null);
  const [blockEl, setBlockEl] = useState<HTMLDivElement | null>(null);
  // Fetch and cache colors.
  // The hook handles triggering re-renders when data arrives.
  useColors();

  // BlockNote applies ProseMirror-selectednode (and its built-in outline CSS) only when ProseMirror creates a NodeSelection.
  // When the cursor is in a paragraph above the WP block and the user clicks the block, ProseMirror resolves the click
  // as a TextSelection at the end of that paragraph rather than a NodeSelection on the block. The class is never applied
  // and the outline never appears. So we set the outline ourselves.
  const selectedBlocks = useSelectedBlocks(editor);
  const isBlockSelected = selectedBlocks.some((b) => b.id === block.id);
  const [isOptionsOpen, setIsOptionsOpen] = useState(false);

  useEffect(() => {
    if (!isBlockSelected) return;
    hideSafariPhantomSelection(editor);
    return editor.onSelectionChange(() => hideSafariPhantomSelection(editor));
  }, [isBlockSelected, editor]);

  useSuppressFormattingToolbar(editor, isOptionsOpen);

  const workPackageResult = useWorkPackage(block.props.wpid);
  const selectedWorkPackage = workPackageResult.workPackage;

  useEffect(() => {
    if (!selectedWorkPackage) return;
    if (selectedWorkPackage.displayId === block.props.displayId) return;
    editor.updateBlock(block, {
      props: { ...block.props, displayId: selectedWorkPackage.displayId },
    });
  }, [selectedWorkPackage?.displayId]); // eslint-disable-line react-hooks/exhaustive-deps

  const cardSize:BlockWpSize = block.props.size ?? 'm';
  // The stored displayId may be '' (schema default), so ?? is not enough here.
  // eslint-disable-next-line @typescript-eslint/prefer-nullish-coalescing
  const displayId = block.props.displayId || String(block.props.wpid);

  // Read once into state: the registry entry is dropped on unmount, which
  // StrictMode simulates, and a remount must not lose a filled form.
  const [pendingMode, setPendingMode] = useState(() => pendingBlockRegistry.mode(block.id));

  useEffect(() => {
    return () => { pendingBlockRegistry.delete(block.id); };
  }, [block.id]);

  const resolvePending = () => {
    pendingBlockRegistry.delete(block.id);
    setPendingMode(undefined);
  };

  const handleSelectWorkPackage = (wp:WorkPackage) => {
    resolvePending();
    editor.updateBlock(block, {
      props: { ...block.props, wpid: wp.id, displayId: wp.displayId },
    });
    requestAnimationFrame(() => moveCursorAfterBlock(editor, block.id));
  };

  const handleCancelPending = () => {
    resolvePending();
    // The slash command consumed the paragraph the cursor was in, so cancelling
    // has to put one back and leave the caret where it started.
    const [restored] = editor.insertBlocks([{ type: 'paragraph' }], block, 'before');
    editor.removeBlocks([block]);
    editor.focus();
    if (restored?.id) editor.setTextCursorPosition(restored.id, 'end');
  };

  // Delegate the drag to the same mechanism the side menu uses internally,
  // so dragging the block directly behaves identically to dragging via the handle.
  const handleBlockDragStart = (e:React.DragEvent) => {
    const sideMenu = editor.extensions.get('sideMenu') as SideMenuInstance | undefined;
    // eslint-disable-next-line @typescript-eslint/no-explicit-any, @typescript-eslint/no-unsafe-argument
    sideMenu?.blockDragStart(e.nativeEvent, block as any);
  };

  // Close options popover on outside click
  useEffect(() => {
    if (!isOptionsOpen) return;
    const handleClickOutside = (e:MouseEvent) => {
      const path = e.composedPath();
      if (cardRef.current && !path.includes(cardRef.current)) {
        setIsOptionsOpen(false);
      }
    };
    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, [isOptionsOpen]);

  const handleConvertToInline = (size:InlineWpSize) => {
    if (!block.props.wpid) return;
    convertBlockToInlineChip(editor, block.id, block.props.wpid, size);
  };

  const handleResizeBlock = (size:BlockWpSize) => {
    editor.updateBlock(block, {
      props: { ...block.props, size },
    });
  };

  const handleRemove = () => {
    editor.removeBlocks([block]);
  };

  const trackBlockElement = (node:HTMLDivElement | null) => {
    if (pendingMode === 'create' || node === null) setBlockEl(node);
  };

  const optionsPopover = (
    <WpOptionsPopover
      wp={selectedWorkPackage ?? undefined}
      displayId={displayId}
      currentSize={undefined}
      currentBlockSize={cardSize}
      // eslint-disable-next-line react-hooks/refs
      anchorEl={cardRef.current}
      onClose={() => setIsOptionsOpen(false)}
      onConvertToInline={handleConvertToInline}
      onConvertToBlock={handleResizeBlock}
      onResizeBlock={handleResizeBlock}
      onRemove={handleRemove}
    />
  );

  return (
    <Block ref={trackBlockElement} $pending={pendingMode !== undefined} $selected={isBlockSelected} data-selected={isBlockSelected || undefined} draggable="true" onDragStart={handleBlockDragStart}>
      <div contentEditable={false}>
        {pendingMode === 'create' && blockEl && (
          <CreateWorkPackageModal
            anchorEl={blockEl}
            onCreated={handleSelectWorkPackage}
            onCancel={handleCancelPending}
          />
        )}

        {pendingMode === 'link' && (
          <SearchContainer $floating>
            <SearchLabel>
              {t('search.label')}
            </SearchLabel>
            <SearchDropdown
              autoFocus
              onSelect={handleSelectWorkPackage}
              onCancel={handleCancelPending}
              renderItem={(wp) => <BlockCard workPackage={wp} inDropdown />}
            />
          </SearchContainer>
        )}

        {block.props.wpid && (
          <>
            {workPackageResult.loading && (
              <UnavailableCard
                headerKey="unavailableWorkPackage.loading.header"
                messageKey="unavailableWorkPackage.loading.message"
              />
            )}
            {!workPackageResult.loading && (workPackageResult.error ?? workPackageResult.unauthorized) && (
              <UnavailableCardWrapper
                ref={cardRef}
                role="button"
                onClick={(e) => {
                  e.stopPropagation();
                  setIsOptionsOpen((prev) => !prev);
                }}
              >
                {workPackageResult.error ? (
                  <UnavailableCard
                    icon={<AlertIcon size={16} />}
                    headerKey="unavailableWorkPackage.error.header"
                    messageKey="unavailableWorkPackage.error.message"
                    displayId={displayId}
                  />
                ) : (
                  <UnavailableCard
                    icon={<EyeClosedIcon size={16} />}
                    headerKey="unavailableWorkPackage.unauthorized.header"
                    messageKey="unavailableWorkPackage.unauthorized.message"
                    displayId={displayId}
                    linkHeader
                  />
                )}
                {isOptionsOpen && optionsPopover}
              </UnavailableCardWrapper>
            )}
            {!workPackageResult.loading &&
              !workPackageResult.error &&
              !workPackageResult.unauthorized &&
              selectedWorkPackage && (
                <BlockCardWrapper>
                  <BlockCard
                    ref={cardRef}
                    workPackage={selectedWorkPackage}
                    size={cardSize}
                    linkTitle
                    onClick={(e) => {
                      e.stopPropagation();
                      setIsOptionsOpen((prev) => !prev);
                    }}
                  />
                  {isOptionsOpen && optionsPopover}
                </BlockCardWrapper>
              )}
          </>
        )}
      </div>
    </Block>
  );
};

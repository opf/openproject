import { BlockNoteEditor, SideMenuExtension } from '@blocknote/core';
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
import { defaultWpVariables } from '../WorkPackage/atoms';
import { CHIP_STYLES } from '../WorkPackage/tokens';
import { moveCursorAfterBlock } from '../../utils/cursor';
import { pendingBlockRegistry } from './pendingBlockRegistry';

const Block = styled.div.attrs({ className: 'op-bn-extensions', 'data-testid': 'block-wp-wrapper' })<{ $pending?:boolean; $selected?:boolean }>`
  ${defaultWpVariables}
  background-color: ${({ $pending }) => ($pending ? 'transparent' : 'var(--op-chip-bg)')};
  user-select: all;
  border-radius: var(--bn-border-radius);
  box-shadow: ${({ $selected }) => ($selected ? CHIP_STYLES.focusShadow : 'none')};
  ${({ $pending }) => $pending && 'position: relative;'}
`;

const BlockCardWrapper = styled.div`
  position: relative;
  display: inline-block;
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

  useEffect(() => {
    return () => { pendingBlockRegistry.delete(block.id); };
  }, [block.id]);

  const handleSelectWorkPackage = (wp:WorkPackage) => {
    pendingBlockRegistry.delete(block.id);
    editor.updateBlock(block, {
      props: { ...block.props, wpid: wp.id, displayId: wp.displayId },
    });
    requestAnimationFrame(() => moveCursorAfterBlock(editor, block.id));
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
      if (cardRef.current && !path.includes(cardRef.current as EventTarget)) {
        setIsOptionsOpen(false);
      }
    };
    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, [isOptionsOpen]);

  const handleConvertToInline = (size:InlineWpSize) => {
    if (!selectedWorkPackage) return;
    convertBlockToInlineChip(editor, block.id, selectedWorkPackage.id, size);
  };

  const handleResizeBlock = (size:BlockWpSize) => {
    editor.updateBlock(block, {
      props: { ...block.props, size },
    });
  };

  const handleRemove = () => {
    editor.removeBlocks([block]);
  };

  const isPending = pendingBlockRegistry.has(block.id);

  return (
    <Block $pending={isPending} $selected={isBlockSelected} data-selected={isBlockSelected || undefined} draggable="true" onDragStart={handleBlockDragStart}>
      <div contentEditable={false} style={{ userSelect: 'none' }}>
        {isPending && (
          <SearchContainer $floating>
            <SearchLabel>
              {t('search.label')}
            </SearchLabel>
            <SearchDropdown
              autoFocus
              onSelect={handleSelectWorkPackage}
              onCancel={() => {
                pendingBlockRegistry.delete(block.id);
                editor.removeBlocks([block]);
                editor.focus();
              }}
              renderItem={(wp) => <BlockCard workPackage={wp} inDropdown />}
            />
          </SearchContainer>
        )}

        {block.props.wpid && (
          <>
            {workPackageResult.loading && (
              <UnavailableCard
                header={t('unavailableWorkPackage.loading.header')}
                message={t('unavailableWorkPackage.loading.message')}
              />
            )}
            {!workPackageResult.loading && workPackageResult.error && (
              <UnavailableCard
                icon={<AlertIcon size={16} />}
                header={t('unavailableWorkPackage.error.header')}
                message={t('unavailableWorkPackage.error.message')}
              />
            )}
            {!workPackageResult.loading && !workPackageResult.error && workPackageResult.unauthorized && (
              <UnavailableCard
                icon={<EyeClosedIcon size={16} />}
                header={t('unavailableWorkPackage.unauthorized.header')}
                message={t('unavailableWorkPackage.unauthorized.message')}
              />
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
                  {isOptionsOpen && (
                    <WpOptionsPopover
                      wp={selectedWorkPackage}
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
                  )}
                </BlockCardWrapper>
              )}
          </>
        )}
      </div>
    </Block>
  );
};

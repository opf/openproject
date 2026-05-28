import { BlockNoteEditor, SideMenuExtension } from '@blocknote/core';
import { useCallback, useEffect, useRef, useState } from 'react';
import styled from 'styled-components';
import { useTranslation } from 'react-i18next';
import { useWorkPackage } from '../../hooks/useWorkPackage';
import { useColors } from '../../services/colors';
import { wpBridge } from '../../services/wpBridge';
import type { WorkPackage } from '../../openProjectTypes';
import type { InlineWpSize, BlockWpSize } from '../WorkPackage/types';
import { BlockCard } from './BlockCard';
import { UnavailableCard } from '../WorkPackage/UnavailableCard';
import { WpOptionsPopover } from '../WorkPackage/OptionsPopover';
import { SearchContainer, SearchLabel } from '../Search/SearchContainer';
import { SearchDropdown } from '../Search/SearchDropdown';
import { defaultWpVariables } from '../WorkPackage/atoms';
import { formatWorkPackageId } from '../../utils/id';
import { moveCursorAfterBlock } from '../../utils/cursor';
import { pendingBlockRegistry } from './pendingBlockRegistry';

const Block = styled.div.attrs({ className: 'op-bn-extensions' })<{ $pending?:boolean }>`
  ${defaultWpVariables}
  background-color: ${({ $pending }) => ($pending ? 'transparent' : 'var(--op-chip-bg)')};
  user-select: all;
  border-radius: var(--bn-border-radius);
  ${({ $pending }) => $pending && 'position: relative;'}
`;

const BlockCardWrapper = styled.div`
  position: relative;
  display: inline-block;
`;

type SideMenuInstance = NonNullable<ReturnType<ReturnType<typeof SideMenuExtension>>>;

interface BlockProps {
  id:string;
  props:{
    wpid?:number;
    size?:BlockWpSize;
  };
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

  const [isOptionsOpen, setIsOptionsOpen] = useState(false);

  const workPackageResult = useWorkPackage(block.props.wpid);
  const selectedWorkPackage = workPackageResult.workPackage;

  useEffect(() => {
    if (!selectedWorkPackage) return;
    // eslint-disable-next-line @typescript-eslint/no-explicit-any, @typescript-eslint/no-unsafe-member-access
    if (selectedWorkPackage.displayId === (block.props as any).displayId) return;
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

  const handleCopy = useCallback(
    (e:ClipboardEvent) => {
      if (!isOptionsOpen || !block.props.wpid) return;

      e.preventDefault();
      e.stopPropagation();

      const wpid = block.props.wpid;
      const formattedId = formatWorkPackageId(selectedWorkPackage?.displayId ?? String(wpid));

      e.clipboardData?.setData('text/plain', formattedId);
      e.clipboardData?.setData(
        'text/html',
        `<div data-block-content-type="openProjectWorkPackageBlock" data-wpid="${wpid}" data-size="${cardSize}" data-initialized="true">${formattedId}</div>`,
      );
    },
    [isOptionsOpen, block.props.wpid, cardSize, selectedWorkPackage],
  );

  useEffect(() => {
    if (!isOptionsOpen) return;

    // Chrome doesn't expose clipboardData on copy events that bubble past a
    // shadow boundary - attach to the nearest root to get a writable event.
    const root = (cardRef.current?.getRootNode() ?? document) as Document | ShadowRoot;
    root.addEventListener('copy', handleCopy as EventListener);
    return () => root.removeEventListener('copy', handleCopy as EventListener);
  }, [isOptionsOpen, handleCopy]);

  const handleConvertToInline = (size:InlineWpSize) => {
    if (!selectedWorkPackage) return;
    wpBridge.convertToInline({ wpid: selectedWorkPackage.id, size, blockId: block.id });
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
    <Block $pending={isPending} draggable="true" onDragStart={handleBlockDragStart}>
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
                header={t('unavailableWorkPackage.error.header')}
                message={t('unavailableWorkPackage.error.message')}
              />
            )}
            {!workPackageResult.loading && !workPackageResult.error && workPackageResult.unauthorized && (
              <UnavailableCard
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
                      instanceId={undefined}
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

import { useRef } from 'react';
import type { WorkPackage } from '../../openProjectTypes';
import { SearchContainer } from './SearchContainer';
import { SearchDropdown } from './SearchDropdown';
import { BlockCard } from '../BlockWorkPackage/BlockCard';
import { useAnchoredPopover, PopoverPortal } from '../WorkPackage/anchoredPopover';
import { useElementHeight } from '../../hooks/useElementHeight';
import { useCanCreateWorkPackages } from '../../hooks/useCanCreateWorkPackages';

// Fits all MAX_SEARCH_RESULTS and the create entry below them, with room for a subject that wraps.
const MAX_POPOVER_HEIGHT = 440;

interface WorkPackageSearchPopoverProps {
  anchorEl?:HTMLElement | null;
  onSelect:(wp:WorkPackage) => void;
  onCancel:() => void;
  onCreate?:(subject:string) => void;
}

export const WorkPackageSearchPopover = ({
  anchorEl,
  onSelect,
  onCancel,
  onCreate,
}:WorkPackageSearchPopoverProps) => {
  const canCreate = useCanCreateWorkPackages();
  const containerRef = useRef<HTMLDivElement>(null);
  const popoverHeight = useElementHeight(containerRef);

  const { side } = useAnchoredPopover({
    anchorEl,
    popoverRef: containerRef,
    placement: 'below',
    maxHeight: MAX_POPOVER_HEIGHT,
    reserveMaxHeight: true,
    resizeKey: popoverHeight,
  });

  return (
    <PopoverPortal anchorEl={anchorEl}>
      <SearchContainer
        ref={containerRef}
        $flipped={side === 'above'}
        onMouseDown={(e) => e.stopPropagation()}
      >
        <SearchDropdown
          autoFocus
          onSelect={onSelect}
          onCancel={onCancel}
          onCreate={canCreate ? onCreate : undefined}
          renderItem={(workPackage) => <BlockCard workPackage={workPackage} inDropdown />}
        />
      </SearchContainer>
    </PopoverPortal>
  );
};

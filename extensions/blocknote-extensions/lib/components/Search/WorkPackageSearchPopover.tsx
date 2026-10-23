import { useRef } from 'react';
import type { WorkPackage } from '../../openProjectTypes';
import { SearchContainer } from './SearchContainer';
import { SearchDropdown } from './SearchDropdown';
import { BlockCard } from '../BlockWorkPackage/BlockCard';
import { useAnchoredPopover, PopoverPortal } from '../WorkPackage/anchoredPopover';
import { useElementHeight } from '../../hooks/useElementHeight';

const MAX_POPOVER_HEIGHT = 360;

interface WorkPackageSearchPopoverProps {
  anchorEl?:HTMLElement | null;
  onSelect:(wp:WorkPackage) => void;
  onCancel:() => void;
}

export const WorkPackageSearchPopover = ({
  anchorEl,
  onSelect,
  onCancel,
}:WorkPackageSearchPopoverProps) => {
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
          renderItem={(workPackage) => <BlockCard workPackage={workPackage} inDropdown />}
        />
      </SearchContainer>
    </PopoverPortal>
  );
};

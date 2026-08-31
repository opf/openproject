import { useRef } from 'react';
import { useTranslation } from 'react-i18next';
import type { WorkPackage } from '../../openProjectTypes';
import { SearchContainer, SearchLabel } from './SearchContainer';
import { SearchDropdown } from './SearchDropdown';
import { BlockCard } from '../BlockWorkPackage/BlockCard';
import { useAnchoredPopover, PopoverPortal } from '../WorkPackage/anchoredPopover';
import { useElementHeight } from '../../hooks/useElementHeight';

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
  const { t } = useTranslation();
  const containerRef = useRef<HTMLDivElement>(null);
  const popoverHeight = useElementHeight(containerRef);

  useAnchoredPopover({
    anchorEl,
    popoverRef: containerRef,
    placement: 'below',
    resizeKey: popoverHeight,
  });

  return (
    <PopoverPortal anchorEl={anchorEl}>
      <SearchContainer
        ref={containerRef}
        onMouseDown={(e) => e.stopPropagation()}
      >
        <SearchLabel>{t('search.label')}</SearchLabel>
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

import { useTranslation } from 'react-i18next';
import type { WorkPackage } from '../../openProjectTypes';
import { SearchContainer, SearchLabel } from './SearchContainer';
import { SearchDropdown } from './SearchDropdown';

interface WorkPackageSearchPopoverProps {
  onSelect:(wp:WorkPackage) => void;
  onCancel:() => void;
  renderItem:(wp:WorkPackage) => React.ReactNode;
}

// Floating search popover for inline work package chip.
export const WorkPackageSearchPopover = ({
  onSelect,
  onCancel,
  renderItem,
}:WorkPackageSearchPopoverProps) => {
  const { t } = useTranslation();

  return (
    <SearchContainer
      $floating
      className="op-bn-inline-search"
      onMouseDown={(e) => e.stopPropagation()}
    >
      <SearchLabel>{t('search.label')}</SearchLabel>
      <SearchDropdown
        autoFocus
        onSelect={onSelect}
        onCancel={onCancel}
        renderItem={renderItem}
      />
    </SearchContainer>
  );
};
import { useTranslation } from "react-i18next";
import styled from "styled-components";
import type { WorkPackage } from "../../openProjectTypes";
import { defaultWpVariables } from "../WorkPackage/atoms";
import { SearchDropdown } from "./SearchDropdown";
import { SearchLabel } from "./SearchContainer";

interface WorkPackageSearchPopoverProps {
  onSelect: (wp: WorkPackage) => void;
  onCancel: () => void;
  renderItem: (wp: WorkPackage) => React.ReactNode;
}

export const WorkPackageSearchPopover = ({ onSelect, onCancel, renderItem }: WorkPackageSearchPopoverProps) => {
  const { t } = useTranslation();

  return (
    <SearchPopover onMouseDown={(e) => e.stopPropagation()}>
      <SearchLabel>
        {t("search.label")}
      </SearchLabel>
      <SearchDropdown
        autoFocus
        onSelect={onSelect}
        onCancel={onCancel}
        renderItem={renderItem}
      />
    </SearchPopover>
  );
};

const SearchPopover = styled.div.attrs({ className: "op-bn-inline-search" })`
  ${defaultWpVariables}
  position: absolute;
  z-index: 9999;
  background-color: var(--bn-colors-menu-background, #fff);
  box-shadow: var(--bn-shadow-medium);
  border-radius: var(--bn-border-radius-large);
  padding: var(--spacer-m) var(--spacer-xl);
  width: 400px;
  top: 1.6em;
  left: 0;
  overflow: hidden;
`;
import { useEffect, useRef, useState } from "react";
import styled from "styled-components";
import { useWorkPackage } from "../../hooks/useWorkPackage";
import { useColors } from "../../services/colors";
import { CHIP_STYLES } from "../WorkPackage/tokens";
import { ChipBase } from "./chipLayouts";
import { WorkPackageId } from "../WorkPackage/atoms";
import { WpChipXXS, WpChipXS, WpChipS } from "./InlineChips";
import { WorkPackageSearchPopover } from "../Search/WorkPackageSearchPopover";
import { WpOptionsPopover } from "../WorkPackage/OptionsPopover";
import { getPendingCallbacks, clearInlineWpCallbacks } from "./callbacks";
import type { InlineWpSize } from "../WorkPackage/types";
import { wpBridge } from "../../services/wpBridge";
import { BlockCard } from "../BlockWorkPackage/BlockCard";
import { useTranslation } from "react-i18next";
import { defaultWpVariables } from "../WorkPackage/atoms";
import { formatWorkPackageId } from "../../utils/id";
import { useIsNodeInSelection } from "../../hooks/useIsNodeInSelection";

export interface InlineWorkPackageChipProps {
  inlineContent: { props: { wpid: string; size: string; instanceId: string } };
  contentRef: (node: HTMLElement | null) => void;
  editor?: any;
}

const InlineChip = styled.span.attrs({
  className: "op-bn-inline-wp",
  contentEditable: false,
})<{ selected?: boolean }>`
  ${defaultWpVariables}
  display: inline-flex;
  align-items: center;
  vertical-align: middle;
  cursor: pointer;
  user-select: none;
  border-radius: ${CHIP_STYLES.radius};
  outline: ${({ selected }) => (selected ? CHIP_STYLES.focusOutline : "none")};
  outline-offset: 1px;
  box-shadow: ${({ selected }) => (selected ? CHIP_STYLES.focusShadow : "none")};
  position: relative;
  max-width: 100%;
  line-height: 1;

  &:active {
    cursor: grabbing;
  }
`;

export const InlineWorkPackageChip = ({ inlineContent, contentRef, editor }: InlineWorkPackageChipProps) => {
  const { t } = useTranslation();
  const rawWpid = inlineContent.props.wpid;
  const size = (inlineContent.props.size ?? "s") as InlineWpSize;
  const instanceId = inlineContent.props.instanceId;

  const pendingCallbacks = getPendingCallbacks(rawWpid);
  const wpid = pendingCallbacks === undefined && rawWpid ? Number(rawWpid) : undefined;

  useColors();

  const { workPackage: wp, loading } = useWorkPackage(wpid);

  const [isSelected, setIsSelected] = useState(false);
  const chipRef = useRef<HTMLElement | null>(null);

  const isEditorSelected = useIsNodeInSelection(chipRef, editor);

  const setRef = (node: HTMLElement | null) => {
    chipRef.current = node;
    contentRef(node);
  };

  // Close the options popover when the user clicks outside the chip
  useEffect(() => {
    if (!isSelected) return;
    const onClickOutside = (e: MouseEvent) => {
      if (chipRef.current && !chipRef.current.contains(e.target as Node)) {
        setIsSelected(false);
      }
    };
    document.addEventListener("mousedown", onClickOutside);
    return () => document.removeEventListener("mousedown", onClickOutside);
  }, [isSelected]);

  // Pending: waiting for user to pick a WP via search
  if (pendingCallbacks) {
    return (
      <InlineChip ref={setRef}>
        <WorkPackageSearchPopover
          onSelect={(selectedWp) => {
            pendingCallbacks.onSelect(selectedWp.id, selectedWp.displayId);
            clearInlineWpCallbacks(instanceId);
          }}
          onCancel={() => {
            pendingCallbacks.onCancel();
            clearInlineWpCallbacks(instanceId);
          }}
          renderItem={(wp) => <BlockCard workPackage={wp} inDropdown />}
        />
      </InlineChip>
    );
  }

  // Loading
  if (wpid && loading) {
    return (
      <InlineChip ref={setRef} selected={isEditorSelected} data-drag-handle>
        <ChipBase>
          <WorkPackageId as="span" $compact>#{wpid}…</WorkPackageId>
        </ChipBase>
      </InlineChip>
    );
  }

  // Resolved
  if (wpid && wp) {
    return (
      <InlineChip
        data-drag-handle
        role="button"
        aria-label={t("options.chipAriaLabel", { id: formatWorkPackageId(wp.displayId) })}
        ref={setRef}
        selected={isSelected || isEditorSelected}
        onClick={(e) => {
          e.preventDefault();
          e.stopPropagation();
          setIsSelected((prev) => !prev);
        }}
      >
        {size === "xxs" && <WpChipXXS wp={wp} />}
        {size === "xs" && <WpChipXS wp={wp} />}
        {size === "s" && <WpChipS wp={wp} />}

        {isSelected && (
          <WpOptionsPopover
            wp={wp}
            currentSize={size}
            instanceId={instanceId}
            anchorEl={chipRef.current}
            onClose={() => setIsSelected(false)}
            onResize={(newSize) => {
              wpBridge.resize({ instanceId, wpid: wp.id, size: newSize });
            }}
            onConvertToBlock={(blockSize) => {
              wpBridge.resize({ instanceId, wpid: wp.id, size: blockSize });
            }}
            onRemove={() => {
              wpBridge.delete({ instanceId, wpid: wp.id });
            }}
          />
        )}
      </InlineChip>
    );
  }

  // Error / unknown
  if (wpid) {
    return (
      <InlineChip ref={setRef} data-drag-handle selected={isEditorSelected} style={{ opacity: 0.6 }}>
        <ChipBase>
          <WorkPackageId as="span" $compact>#{wpid}</WorkPackageId>
        </ChipBase>
      </InlineChip>
    );
  }

  return <InlineChip ref={setRef} />;
};
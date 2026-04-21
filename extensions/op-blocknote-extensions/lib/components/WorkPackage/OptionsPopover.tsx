import { useState } from "react";
import type { WorkPackage } from "../../openProjectTypes";
import { linkToWorkPackage } from "../../services/openProjectApi";
import type { InlineWpSize, BlockWpSize, WpSize } from "./types";
import styled from "styled-components";
import { defaultWpVariables } from "./atoms";
import {
  LinkExternalIcon,
  TrashIcon,
  ScreenFullIcon,
  ChevronDownIcon,
} from "@primer/octicons-react";

export interface WpOptionsProps {
  wp: WorkPackage;
  currentSize?: InlineWpSize;
  currentBlockSize?: BlockWpSize;
  instanceId?: string;
  onClose: () => void;
  onResize?: (size: InlineWpSize) => void;
  onRemove?: () => void;
  onConvertToBlock?: (size: BlockWpSize) => void;
  onConvertToInline?: (size: InlineWpSize) => void;
  onResizeBlock?: (size: BlockWpSize) => void;
}

const SIZE_META: Record<WpSize, { label: string; desc: string }> = {
  xxs: { label: "Tiny (inline)", desc: "Identifier" },
  xs:  { label: "Compact (inline)", desc: "Type, Identifier, Subject" },
  s:   { label: "Regular (inline)", desc: "Status, Type, Identifier, Subject" },
  m:   { label: "Compact card", desc: "Compact card - Status, Type, Identifier, Subject" },
  l:   { label: "Regular card", desc: "Regular card - Identifier, Subject, Type, Status, Parent, Project" },
  xl:  { label: "Full card", desc: "Full card - Identifier, Subject, Type, Status, Parent, Project, Description" },
};


const INLINE_SIZE_OPTIONS: WpSize[] = ["xxs", "xs", "s", "m", "l", "xl"];
const BLOCK_SIZE_OPTIONS: BlockWpSize[] = ["m", "l", "xl"];
const BLOCK_TO_INLINE_OPTIONS: InlineWpSize[] = ["xxs", "xs", "s"];

const BLOCK_SIZES = new Set<WpSize>(["m", "l", "xl"]);

export const WpOptionsPopover = ({
  wp,
  currentSize,
  currentBlockSize,
  instanceId: _instanceId,
  onClose,
  onResize,
  onRemove,
  onConvertToBlock,
  onConvertToInline,
  onResizeBlock,
}: WpOptionsProps) => {
  const [showSizes, setShowSizes] = useState(false);

  const isBlock = currentSize === undefined;
  const displayedSize = isBlock
    ? SIZE_META[currentBlockSize ?? "m"].label
    : SIZE_META[currentSize].label;

  const closeMenu = () => {
    setShowSizes(false);
    onClose();
  };

  const handleInlineSizeSelect = (size: WpSize) => {
    if (isBlock) {
      onConvertToInline?.(size as InlineWpSize);
    } else if (BLOCK_SIZES.has(size)) {
      onConvertToBlock?.(size as BlockWpSize);
    } else {
      onResize?.(size as InlineWpSize);
    }
    closeMenu();
  };

  const handleBlockSizeSelect = (size: BlockWpSize) => {
    onResizeBlock?.(size);
    closeMenu();
  };

  return (
    // Prevent editor/parent handlers from stealing focus or closing the popover
    <Popover onMouseDown={(e) => e.stopPropagation()}>
      <PopBtn
        title="Open in new tab"
        aria-label={`Open work package #${wp.id} in new tab`}
        onClick={(e) => {
          e.stopPropagation();
          window.open(linkToWorkPackage(wp.id), "_blank", "noopener,noreferrer");
        }}
      >
        <IcOpen /> Open
      </PopBtn>

      <Divider />

      <SizeButtonWrapper>
        <PopBtn
          title="Change size"
          aria-label="Change size"
          onClick={(e) => {
            e.stopPropagation();
            setShowSizes((prev) => !prev);
          }}
        >
          <IcSize />
          {displayedSize}
          <IcChevron />
        </PopBtn>

        {showSizes && (
          <SizeMenu onMouseDown={(e) => e.stopPropagation()}>
            {isBlock ? (
              <>
                <SizeMenuLabel>Block size</SizeMenuLabel>
                {BLOCK_SIZE_OPTIONS.map((size) => {
                  const option = SIZE_META[size];
                  return (
                    <SizeBtn
                      key={size}
                      aria-label={option.label}
                      $active={currentBlockSize === size}
                      onMouseDown={(e) => {
                        e.preventDefault();
                        e.stopPropagation();
                        handleBlockSizeSelect(size);
                      }}
                    >
                      <SizeBtnLabel>{option.label}</SizeBtnLabel>
                      <SizeBtnDesc>{option.desc}</SizeBtnDesc>
                    </SizeBtn>
                  );
                })}

                <SizeMenuDivider />

                <SizeMenuLabel>Convert to inline</SizeMenuLabel>
                {BLOCK_TO_INLINE_OPTIONS.map((size) => {
                  const option = SIZE_META[size];
                  return (
                    <SizeBtn
                      key={size}
                      aria-label={option.label}
                      $active={false}
                      onMouseDown={(e) => {
                        e.preventDefault();
                        e.stopPropagation();
                        handleInlineSizeSelect(size);
                      }}
                    >
                      <SizeBtnLabel>{option.label}</SizeBtnLabel>
                      <SizeBtnDesc>{option.desc}</SizeBtnDesc>
                    </SizeBtn>
                  );
                })}
              </>
            ) : (
              <>
                <SizeMenuLabel>Change size</SizeMenuLabel>
                {INLINE_SIZE_OPTIONS.map((size) => {
                  const option = SIZE_META[size];
                  return (
                    <SizeBtn
                      key={size}
                      aria-label={option.label}
                      $active={currentSize === size}
                      // Use mousedown to avoid losing focus before click fires (important for editor integrations)
                      onMouseDown={(e) => {
                        e.preventDefault();
                        e.stopPropagation();
                        handleInlineSizeSelect(size);
                      }}
                    >
                      <SizeBtnLabel>{option.label}</SizeBtnLabel>
                      <SizeBtnDesc>{option.desc}</SizeBtnDesc>
                    </SizeBtn>
                  );
                })}
              </>
            )}
          </SizeMenu>
        )}
      </SizeButtonWrapper>

      <Divider />

      <PopBtn
        $danger
        title="Remove"
        data-testid="remove-btn"
        aria-label="Remove work package"
        onClick={(e) => {
          e.stopPropagation();
          onRemove?.();
          onClose();
        }}
      >
        <IcDelete /> Remove
      </PopBtn>
    </Popover>
  );
};

const Popover = styled.div.attrs({
  className: "op-bn-inline-options",
  "data-testid": "popover-content",
})`
  ${defaultWpVariables}
  position: absolute;
  z-index: 9999;
  background-color: var(--bn-colors-menu-background, #fff);
  box-shadow: var(--bn-shadow-medium);
  border-radius: var(--bn-border-radius-large);
  padding: var(--spacer-s);
  display: flex;
  align-items: center;
  gap: 2px;
  bottom: calc(100% + 6px);
  left: 0;
  white-space: nowrap;
`;

const PopBtn = styled.button<{ $danger?: boolean }>`
  background: none;
  border: none;
  border-radius: var(--bn-border-radius-small);
  padding: var(--spacer-s) var(--spacer-m);
  cursor: pointer;
  font-size: 0.82em;
  color: ${({ $danger }) =>
    $danger
      ? "var(--mantine-color-red-8)"
      : "var(--bn-colors-editor-text, #333)"};
  display: flex;
  align-items: center;
  gap: var(--spacer-s);
  line-height: 1;
  &:hover {
    background-color: var(
      --bn-colors-highlights-gray-background,
      #f5f5f5
    );
  }
  svg { flex-shrink: 0; }
`;

const Divider = styled.div`
  width: 1px;
  height: 18px;
  background: var(--mantine-color-default-border);
  margin: 0 2px;
`;

const SizeButtonWrapper = styled.div`
  position: relative;
`;

const SizeMenu = styled.div.attrs<{
  "data-testid"?: string;
}>({
  "data-testid": "size-menu",
})`
  position: absolute;
  top: calc(100% + var(--spacer-s));
  left: 0;
  z-index: 10000;
  background: var(--bn-colors-menu-background, #fff);
  box-shadow: var(--bn-shadow-medium);
  border-radius: var(--bn-border-radius-large);
  padding: var(--spacer-s);
  min-width: 200px;
`;

const SizeMenuLabel = styled.div`
  padding: var(--spacer-s) var(--spacer-m);
  font-size: 0.75em;
  opacity: 0.5;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.05em;
`;

const SizeMenuDivider = styled.div`
  height: 1px;
  background: var(--mantine-color-default-border);
  margin: var(--spacer-s) 0;
`;

const SizeBtn = styled.button<{ $active?: boolean }>`
  display: flex;
  align-items: center;
  gap: var(--spacer-m);
  width: 100%;
  background: ${({ $active }) =>
    $active
      ? "var(--bn-colors-highlights-gray-background, #f0f0f0)"
      : "none"};
  border: none;
  border-radius: var(--bn-border-radius-small);
  padding: var(--spacer-s) var(--spacer-m);
  cursor: pointer;
  font-size: 0.82em;
  color: var(--bn-colors-editor-text, #333);
  text-align: left;
  &:hover { background: var(--bn-colors-highlights-gray-background, #f0f0f0); }
`;

const SizeBtnLabel = styled.strong`
  min-width: 28px;
`;

const SizeBtnDesc = styled.span`
  opacity: 0.6;
`;

const IcOpen = () => <LinkExternalIcon size={13} />;
const IcDelete = () => <TrashIcon size={13} />;
const IcSize = () => <ScreenFullIcon size={13} />;
const IcChevron = () => <ChevronDownIcon size={10} />;
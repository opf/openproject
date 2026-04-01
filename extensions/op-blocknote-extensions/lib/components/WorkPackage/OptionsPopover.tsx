import { useState } from "react";
import type { WorkPackage } from "../../openProjectTypes";
import { linkToWorkPackage } from "../../services/openProjectApi";
import type { InlineWpSize } from "../InlineWorkPackage/types";
import styled from "styled-components";
import { defaultWpVariables } from "./atoms";
import {
  LinkExternalIcon,
  TrashIcon,
  ScreenFullIcon,
  ChevronDownIcon,
  ColumnsIcon,
} from "@primer/octicons-react";

export interface WpOptionsProps {
  wp: WorkPackage;
  currentSize?: InlineWpSize;
  instanceId?: string;
  onClose: () => void;
  onResize?: (size: InlineWpSize) => void;
  onRemove?: () => void;
  onConvertToInline?: (size: InlineWpSize) => void;
}

const SIZE_OPTIONS: { value: InlineWpSize; label: string; desc: string }[] = [
  { value: "xxs", label: "XXS", desc: "ID" },
  { value: "xs",  label: "XS",  desc: "ID, Type, Subject" },
  { value: "s",   label: "S",   desc: "ID, Type, Status, Subject" },
  { value: "m",   label: "M",   desc: "Block — full card" },
];

export const WpOptionsPopover = ({
  wp,
  currentSize,
  instanceId: _instanceId,
  onClose,
  onResize,
  onRemove,
  onConvertToInline,
}: WpOptionsProps) => {
  const [showSizes, setShowSizes] = useState(false);
  const isBlock = currentSize === undefined;

  const resize = (size: InlineWpSize) => {
    onResize?.(size);
    setShowSizes(false);
    onClose();
  };

  const remove = () => {
    onRemove?.();
    onClose();
  };

  const convertToInline = (size: InlineWpSize) => {
    onConvertToInline?.(size);
    setShowSizes(false);
    onClose();
  };

  return (
    <Popover onMouseDown={(e) => e.stopPropagation()}>
      <PopBtn
        title="Open"
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
          title={isBlock ? "Convert to inline" : "Change size"}
          aria-label={isBlock ? "Convert to inline" : "Change size"}
          onClick={(e) => {
            e.stopPropagation();
            setShowSizes((prev) => !prev);
          }}
        >
          {isBlock ? <IcInline /> : <IcSize />}
          {isBlock ? "Inline" : (currentSize ?? "s").toUpperCase()}
          <IcChevron />
        </PopBtn>

        {showSizes && (
          <SizeMenu onMouseDown={(e) => e.stopPropagation()}>
            {isBlock && (
              <SizeMenuLabel>Convert to inline</SizeMenuLabel>
            )}

            {(isBlock
              ? SIZE_OPTIONS.filter((option) => option.value !== "m")
              : SIZE_OPTIONS
            ).map((option) => (
              <SizeBtn
                key={option.value}
                aria-label={option.label}
                $active={!isBlock && currentSize === option.value}
                onMouseDown={(e) => {
                  e.preventDefault();
                  e.stopPropagation();
                  isBlock ? convertToInline(option.value) : resize(option.value);
                }}
              >
                <SizeBtnLabel>{option.label}</SizeBtnLabel>
                <SizeBtnDesc>{option.desc}</SizeBtnDesc>
              </SizeBtn>
            ))}
          </SizeMenu>
        )}
      </SizeButtonWrapper>

      <Divider />

      <PopBtn
        $danger
        title="Remove"
        data-testid="remove-btn" 
        onClick={(e) => {
          e.stopPropagation();
          remove();
        }}
      >
        <IcDelete /> Remove
      </PopBtn>
    </Popover>
  );
};

const Popover = styled.div.attrs({ 
  className: "op-bn-inline-options",
  'data-testid': 'popover-content',
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
  color: ${({ $danger }) => ($danger ? "var(--mantine-color-red-8)" : "var(--bn-colors-editor-text, #333)")};
  display: flex;
  align-items: center;
  gap: var(--spacer-s);
  line-height: 1;
  &:hover { background-color: var(--bn-colors-highlights-gray-background, #f5f5f5); }
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
  'data-testid'?: string;
}>({
  'data-testid': 'size-menu',
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

const SizeBtn = styled.button<{ $active?: boolean }>`
  display: flex;
  align-items: center;
  gap: var(--spacer-m);
  width: 100%;
  background: ${({ $active }) => ($active ? "var(--bn-colors-highlights-gray-background, #f0f0f0)" : "none")};
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
const IcInline = () => <ColumnsIcon size={13} />;
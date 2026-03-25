import { useState } from "react";
import { useTranslation } from "react-i18next";
import type { WorkPackage } from "../../openProjectTypes";
import { linkToWorkPackage } from "../../services/openProjectApi";
import type { InlineWpSize } from "./types";

import {
  SearchPopover,
  Popover,
  PopBtn,
  Divider,
  SizeMenu,
  SizeBtn,
  IcOpen,
  IcDelete,
  IcSize,
  IcChevron,
  IcInline,
  SIZE_OPTIONS,
} from "./InlineWorkPackageShared";

import { SearchDropdown } from "../SearchDropdown";

export const InlineSearchPopover = ({
  onSelect,
  onCancel,
}: {
  onSelect: (wp: WorkPackage) => void;
  onCancel: () => void;
}) => {
  const { t } = useTranslation();

  return (
    <SearchPopover onMouseDown={(e) => e.stopPropagation()}>
      <label style={{ fontWeight: "normal" }}>
        {t("search.label")}
        <SearchDropdown
          autoFocus
          onSelect={onSelect}
          onCancel={onCancel}
        />
      </label>
    </SearchPopover>
  );
};

export interface WpOptionsProps {
  wp: WorkPackage;
  // `undefined` means this popover belongs to a block-level card 
  currentSize?: InlineWpSize;
  instanceId?: string;
  onClose: () => void;
  onResize?: (size: InlineWpSize) => void;
  onRemove?: () => void;
  onConvertToInline?: (size: InlineWpSize) => void;
}

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

      <div style={{ position: "relative" }}>
        <PopBtn
          title={isBlock ? "Convert to inline" : "Change size"}
          onClick={(e) => {
            e.stopPropagation();
            setShowSizes((p) => !p);
          }}
        >
          {isBlock ? <IcInline /> : <IcSize />}
          {isBlock ? "Inline" : (currentSize ?? "s").toUpperCase()}
          <IcChevron />
        </PopBtn>

        {showSizes && (
          <SizeMenu onMouseDown={(e) => e.stopPropagation()}>
            {isBlock && (
              <div
                style={{
                  padding: "var(--spacer-s) var(--spacer-m)",
                  fontSize: "0.75em",
                  opacity: 0.5,
                  fontWeight: 600,
                  textTransform: "uppercase",
                  letterSpacing: "0.05em",
                }}
              >
                Convert to inline
              </div>
            )}

            {(isBlock
              ? SIZE_OPTIONS.filter((o) => o.value !== "m")
              : SIZE_OPTIONS
            ).map((opt) => (
              <SizeBtn
                key={opt.value}
                $active={!isBlock && currentSize === opt.value}
                onMouseDown={(e) => {
                  e.preventDefault();
                  e.stopPropagation();
                  isBlock ? convertToInline(opt.value) : resize(opt.value);
                }}
              >
                <strong style={{ minWidth: 28 }}>{opt.label}</strong>
                <span style={{ opacity: 0.6 }}>{opt.desc}</span>
              </SizeBtn>
            ))}
          </SizeMenu>
        )}
      </div>

      <Divider />

      <PopBtn
        $danger
        title="Remove"
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
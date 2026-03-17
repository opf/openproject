import { createReactInlineContentSpec } from "@blocknote/react";
import React, { useEffect, useRef, useState } from "react";
import { useWorkPackage } from "../hooks/useWorkPackage";
import { useWorkPackageSearch } from "../hooks/useWorkPackageSearch";
import type { WorkPackage } from "../openProjectTypes";
import { linkToWorkPackage } from "../services/openProjectApi";
import { useColors } from "../services/colors";
import { WorkPackageElement } from "../elements/workPackageElement";
import styled from "styled-components";
import { useTranslation } from "react-i18next";

// Types

export type InlineWpSize = "xxs" | "xs" | "s" | "m";

// Styled components 

const InlineChip = styled.span.attrs({ className: "op-bn-inline-wp" })<{
  selected?: boolean;
}>`
  display: inline-flex;
  align-items: center;
  vertical-align: middle;
  cursor: pointer;
  user-select: none;
  border-radius: 4px;
  outline: ${({ selected }) => (selected ? "2px solid #1a67a3" : "none")};
  outline-offset: 1px;
  position: relative;
  max-width: 100%;
`;

// Size variants

const ChipXXS = styled.span`
  display: inline-flex;
  align-items: center;
  gap: 3px;
  padding: 1px 6px;
  border-radius: 4px;
  background: var(--bn-colors-highlights-gray-background, #f0f0f0);
  font-size: 0.8em;
  color: var(--bn-colors-highlights-gray-text, #555);
  font-weight: 500;
  white-space: nowrap;
`;

const ChipXS = styled.span`
  display: inline-flex;
  align-items: center;
  gap: 4px;
  padding: 1px 6px 1px 4px;
  border-radius: 4px;
  background: var(--bn-colors-highlights-gray-background, #f0f0f0);
  font-size: 0.82em;
  white-space: nowrap;
  max-width: 320px;
  overflow: hidden;
`;

const ChipS = styled.span`
  display: inline-flex;
  align-items: center;
  gap: 4px;
  padding: 2px 8px 2px 6px;
  border-radius: 100px;
  background: var(--bn-colors-highlights-gray-background, #f0f0f0);
  border: 1px solid rgba(0,0,0,0.08);
  font-size: 0.82em;
  white-space: nowrap;
  max-width: 400px;
  overflow: hidden;
`;

const TypeBadge = styled.span<{ color?: string }>`
  font-size: 0.78em;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 0.03em;
  color: ${({ color }) => color ?? "#1a67a3"};
  flex-shrink: 0;
`;

const IdBadge = styled.span`
  color: var(--bn-colors-highlights-gray-text, #777);
  font-size: 0.85em;
  flex-shrink: 0;
`;

const StatusBadge = styled.span`
  display: inline-flex;
  align-items: center;
  padding: 0 6px;
  border-radius: 100px;
  font-size: 0.78em;
  font-weight: 500;
  background: #e8f4fd;
  color: #1a67a3;
  border: 1px solid rgba(0,0,0,0.1);
  flex-shrink: 0;
  line-height: 1.6;
`;

const TitleText = styled.span`
  color: var(--bn-colors-editor-text, #222);
  font-weight: 500;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
`;

// Options popover (inline chip appears ABOVE) 

const OptionsPopover = styled.div.attrs({ className: "op-bn-inline-options" })`
  position: absolute;
  z-index: 9999;
  background-color: var(--bn-colors-menu-background, #fff);
  box-shadow: 0 4px 16px rgba(0,0,0,0.12), 0 1px 4px rgba(0,0,0,0.08);
  border-radius: 8px;
  padding: 4px;
  display: flex;
  flex-direction: row;
  align-items: center;
  gap: 2px;
  bottom: calc(100% + 6px);
  left: 0;
  white-space: nowrap;
`;

const OptionButton = styled.button<{ $danger?: boolean }>`
  background: none;
  border: none;
  border-radius: 6px;
  padding: 5px 8px;
  cursor: pointer;
  font-size: 0.82em;
  color: ${({ $danger }) => ($danger ? "#c0392b" : "var(--bn-colors-editor-text, #333)")};
  display: flex;
  align-items: center;
  gap: 5px;
  line-height: 1;

  &:hover {
    background-color: var(--bn-colors-highlights-gray-background, #f5f5f5);
  }

  svg { flex-shrink: 0; }
`;

const Divider = styled.div`
  width: 1px;
  height: 18px;
  background: rgba(0,0,0,0.1);
  margin: 0 2px;
`;

const SizeDropdown = styled.div`
  position: absolute;
  top: calc(100% + 4px);
  left: 0;
  z-index: 10000;
  background: var(--bn-colors-menu-background, #fff);
  box-shadow: 0 4px 16px rgba(0,0,0,0.12);
  border-radius: 8px;
  padding: 4px;
  min-width: 200px;
`;

const SizeOption = styled.button<{ $active?: boolean }>`
  display: flex;
  align-items: center;
  gap: 8px;
  width: 100%;
  background: ${({ $active }) => ($active ? "var(--bn-colors-highlights-gray-background, #f0f0f0)" : "none")};
  border: none;
  border-radius: 6px;
  padding: 6px 10px;
  cursor: pointer;
  font-size: 0.82em;
  color: var(--bn-colors-editor-text, #333);
  text-align: left;

  &:hover { background: var(--bn-colors-highlights-gray-background, #f0f0f0); }
`;

// Search popover 

const SearchPopover = styled.div.attrs({ className: "op-bn-inline-search" })`
  position: absolute;
  z-index: 9999;
  background-color: var(--bn-colors-menu-background, #fff);
  box-shadow: 0 4px 16px rgba(0,0,0,0.12);
  border-radius: 8px;
  padding: 8px 16px;
  width: 400px;
  top: 1.6em;
  left: 0;
`;

const SearchInputWrapper = styled.div`
  position: relative;
  margin-top: 8px;
`;

const SearchInput = styled.input`
  width: 100%;
  padding: 8px 12px;
  border: 1px solid #ccc;
  border-radius: 6px;
  background: var(--bn-colors-menu-background, #fff);
  color: var(--bn-colors-editor-text, #333);
  font-size: 0.9em;
`;

const Dropdown = styled.div`
  overflow-y: auto;
  max-height: 240px;
  padding-top: 8px;
`;

const DropdownOption = styled.div<{ $selected: boolean }>`
  background-color: ${({ $selected }) =>
    $selected ? "var(--bn-colors-highlights-gray-background, #f0f0f0)" : "transparent"};
  border-radius: 6px;
  margin: 4px 0;
  padding: 0 8px;
  cursor: pointer;
`;

// Icons

const IconOpen = () => (
  <svg width="13" height="13" viewBox="0 0 16 16" fill="none" stroke="currentColor" strokeWidth="1.8">
    <path d="M7 3H3a1 1 0 0 0-1 1v9a1 1 0 0 0 1 1h9a1 1 0 0 0 1-1V9" />
    <path d="M10 2h4v4" /><path d="M14 2 8 8" />
  </svg>
);

const IconDelete = () => (
  <svg width="13" height="13" viewBox="0 0 16 16" fill="none" stroke="currentColor" strokeWidth="1.8">
    <path d="M3 5h10M6 5V3h4v2M7 8v4M9 8v4M4 5l1 8h6l1-8" />
  </svg>
);

const IconSize = () => (
  <svg width="13" height="13" viewBox="0 0 16 16" fill="none" stroke="currentColor" strokeWidth="1.8">
    <rect x="2" y="5" width="12" height="6" rx="2" /><path d="M5 8h6" />
  </svg>
);

const IconChevron = () => (
  <svg width="10" height="10" viewBox="0 0 16 16" fill="none" stroke="currentColor" strokeWidth="2">
    <path d="M4 6l4 4 4-4" />
  </svg>
);

const IconInline = () => (
  <svg width="13" height="13" viewBox="0 0 16 16" fill="none" stroke="currentColor" strokeWidth="1.8">
    <rect x="1" y="6" width="14" height="4" rx="2" />
  </svg>
);

// Global callback registry

type WpSelectedCallback = (wpid: number) => void;
type WpCancelCallback = () => void;

interface PendingCallbacks {
  onSelect: WpSelectedCallback;
  onCancel: WpCancelCallback;
}

const pendingCallbacks = new Map<string, PendingCallbacks>();

export function registerInlineWpCallbacks(
  key: string,
  onSelect: WpSelectedCallback,
  onCancel: WpCancelCallback
): void {
  pendingCallbacks.set(key, { onSelect, onCancel });
}

export function clearInlineWpCallbacks(key: string): void {
  pendingCallbacks.delete(key);
}

// Size config

// Sizes available for inline chips only (M is block-only, handled separately)
const INLINE_SIZE_OPTIONS: { value: InlineWpSize; label: string; desc: string }[] = [
  { value: "xxs", label: "XXS", desc: "Identifier only" },
  { value: "xs",  label: "XS",  desc: "Type, ID, Subject" },
  { value: "s",   label: "S",   desc: "Status, Type, ID, Subject" },
  { value: "m",   label: "M",   desc: "Block — full card" },
];

// Search popover component

interface InlineSearchProps {
  onSelect: (wp: WorkPackage) => void;
  onCancel: () => void;
}

const InlineSearchPopover = ({ onSelect, onCancel }: InlineSearchProps) => {
  const { t } = useTranslation();
  const inputRef = useRef<HTMLInputElement>(null);
  const isSelectingRef = useRef(false);
  const { searchQuery, setSearchQuery, searchResults } = useWorkPackageSearch();
  const [focusedIndex, setFocusedIndex] = useState(-1);
  const [isDropdownOpen, setIsDropdownOpen] = useState(false);

  useEffect(() => {
    requestAnimationFrame(() => inputRef.current?.focus());
  }, []);

  const handleKeyDown = (e: React.KeyboardEvent<HTMLInputElement>) => {
    switch (e.key) {
      case "ArrowDown":
        e.preventDefault();
        if (!isDropdownOpen) setIsDropdownOpen(true);
        setFocusedIndex((prev) => Math.min(prev + 1, searchResults.length - 1));
        break;
      case "ArrowUp":
        e.preventDefault();
        setFocusedIndex((prev) => Math.max(prev - 1, 0));
        break;
      case "Enter":
        if (focusedIndex >= 0 && searchResults[focusedIndex]) {
          e.preventDefault();
          isSelectingRef.current = true;
          onSelect(searchResults[focusedIndex]);
        }
        break;
      case "Escape":
        onCancel();
        break;
    }
  };

  return (
    <SearchPopover onMouseDown={(e) => e.stopPropagation()}>
      <label style={{ fontWeight: "normal" }}>
        {t("search.label")}
        <SearchInputWrapper>
          <SearchInput
            ref={inputRef}
            type="text"
            placeholder={t("search.placeholder")}
            value={searchQuery}
            onChange={(e) => {
              setSearchQuery(e.target.value);
              setIsDropdownOpen(e.target.value.length > 0);
            }}
            onKeyDown={handleKeyDown}
            onBlur={() => {
              setTimeout(() => {
                if (isSelectingRef.current) { isSelectingRef.current = false; return; }
                onCancel();
              }, 150);
            }}
          />
        </SearchInputWrapper>
      </label>

      {isDropdownOpen && searchResults.length > 0 && (
        <Dropdown>
          {searchResults.slice(0, 5).map((wp, index) => (
            <DropdownOption
              key={wp.id}
              $selected={focusedIndex === index}
              onMouseDown={(e) => {
                e.preventDefault();
                isSelectingRef.current = true;
                onSelect(wp);
              }}
              onMouseEnter={() => setFocusedIndex(index)}
            >
              <WorkPackageElement workPackage={wp} inDropdown="true" />
            </DropdownOption>
          ))}
        </Dropdown>
      )}
    </SearchPopover>
  );
};

// Chip sub-renderers 

const WpChipXXS = ({ wp }: { wp: WorkPackage }) => (
  <ChipXXS><IdBadge>#{wp.id}</IdBadge></ChipXXS>
);

const WpChipXS = ({ wp }: { wp: WorkPackage }) => (
  <ChipXS>
    {wp._links?.type?.title && <TypeBadge>{wp._links.type.title}</TypeBadge>}
    <IdBadge>#{wp.id}</IdBadge>
    <TitleText>{wp.subject}</TitleText>
  </ChipXS>
);

const WpChipS = ({ wp }: { wp: WorkPackage }) => (
  <ChipS>
    {wp._links?.type?.title && <TypeBadge>{wp._links.type.title}</TypeBadge>}
    <IdBadge>#{wp.id}</IdBadge>
    {wp._links?.status?.title && <StatusBadge>{wp._links.status.title}</StatusBadge>}
    <TitleText>{wp.subject}</TitleText>
  </ChipS>
);

// Inline Options Popover component 
// Extracted as component so it can also be used by the block WP spec.

export interface WpOptionsProps {
  wp: WorkPackage;
  /** Current size — undefined means "block mode" (no inline size applies) */
  currentSize?: InlineWpSize;
  /** instanceId of the inline chip (undefined for block WP) */
  instanceId?: string;
  onClose: () => void;
}

export const WpOptionsPopover = ({ wp, currentSize, instanceId, onClose }: WpOptionsProps) => {
  const [showSizeDropdown, setShowSizeDropdown] = useState(false);
  const isBlock = currentSize === undefined;

  const dispatchResize = (newSize: InlineWpSize) => {
    document.dispatchEvent(
      new CustomEvent("op-inline-wp-resize", {
        detail: { instanceId, wpid: wp.id, size: newSize },
      })
    );
    setShowSizeDropdown(false);
    onClose();
  };

  const dispatchDelete = () => {
    document.dispatchEvent(
      new CustomEvent("op-inline-wp-delete", {
        detail: { instanceId, wpid: wp.id },
      })
    );
    onClose();
  };

  // For block WP: "Convert to inline" inserts an inline chip after removing the block
  const dispatchConvertToInline = (size: InlineWpSize) => {
    document.dispatchEvent(
      new CustomEvent("op-block-wp-to-inline", {
        detail: { wpid: wp.id, size },
      })
    );
    setShowSizeDropdown(false);
    onClose();
  };

  return (
    <OptionsPopover onMouseDown={(e) => e.stopPropagation()}>
      {/* Open */}
      <OptionButton
        title="Open work package"
        onClick={(e) => {
          e.stopPropagation();
          window.open(linkToWorkPackage(wp.id), "_blank", "noopener,noreferrer");
        }}
      >
        <IconOpen />
        Open
      </OptionButton>

      <Divider />

      {/* Size / Convert */}
      <OptionButton
        title={isBlock ? "Convert to inline" : "Change size"}
        onClick={(e) => {
          e.stopPropagation();
          setShowSizeDropdown((prev) => !prev);
        }}
      >
        {isBlock ? <IconInline /> : <IconSize />}
        {isBlock ? "Inline" : (currentSize ?? "s").toUpperCase()}
        <IconChevron />

        {showSizeDropdown && (
          <SizeDropdown onMouseDown={(e) => e.stopPropagation()}>
            {isBlock ? (
              // Block → inline: pick which inline size to use
              <>
                <div style={{ padding: "4px 10px 6px", fontSize: "0.75em", opacity: 0.5, fontWeight: 600, textTransform: "uppercase", letterSpacing: "0.05em" }}>
                  Convert to inline
                </div>
                {INLINE_SIZE_OPTIONS.filter((o) => o.value !== "m").map((opt) => (
                  <SizeOption
                    key={opt.value}
                    $active={false}
                    onMouseDown={(e) => {
                      e.preventDefault();
                      e.stopPropagation();
                      dispatchConvertToInline(opt.value);
                    }}
                  >
                    <strong style={{ minWidth: 28 }}>{opt.label}</strong>
                    <span style={{ opacity: 0.6 }}>{opt.desc}</span>
                  </SizeOption>
                ))}
              </>
            ) : (
              // Inline → resize (or convert to block via M)
              INLINE_SIZE_OPTIONS.map((opt) => (
                <SizeOption
                  key={opt.value}
                  $active={currentSize === opt.value}
                  onMouseDown={(e) => {
                    e.preventDefault();
                    e.stopPropagation();
                    dispatchResize(opt.value);
                  }}
                >
                  <strong style={{ minWidth: 28 }}>{opt.label}</strong>
                  <span style={{ opacity: 0.6 }}>{opt.desc}</span>
                </SizeOption>
              ))
            )}
          </SizeDropdown>
        )}
      </OptionButton>

      <Divider />

      {/* Remove */}
      <OptionButton
        $danger
        title="Remove link"
        onClick={(e) => {
          e.stopPropagation();
          dispatchDelete();
        }}
      >
        <IconDelete />
        Remove
      </OptionButton>
    </OptionsPopover>
  );
};

// Inline content spec

export const inlineWorkPackageSpec = createReactInlineContentSpec(
  {
    type: "inlineWorkPackage" as const,
    propSchema: {
      wpid: { default: "" },
      /** Unique instance ID — used to route events to the correct chip */
      instanceId: { default: "" },
      /** Display size — "xxs" | "xs" | "s" | "m". Default "s". */
      size: { default: "s" },
    },
    content: "none",
  },
  {
    render: ({ inlineContent, contentRef }) => {
      const rawWpid = inlineContent.props.wpid;
      const size = (inlineContent.props.size ?? "s") as InlineWpSize;
      // instanceId is stable per chip (set at insertion time by the slash menu handler)
      const instanceId = inlineContent.props.instanceId;

      const isPending = rawWpid.startsWith("pending:");
      const pendingCallbackKey = isPending ? rawWpid.slice("pending:".length) : null;
      const wpid = !isPending && rawWpid ? Number(rawWpid) : undefined;

      useColors();

      const workPackageResult = useWorkPackage(wpid);
      const wp = workPackageResult.workPackage;

      const [isSelected, setIsSelected] = useState(false);
      const chipRef = useRef<HTMLElement | null>(null);

      const setRef = (node: HTMLElement | null) => {
        chipRef.current = node;
        contentRef(node);
      };

      // Close popover on outside click
      useEffect(() => {
        if (!isSelected) return;
        const handleClickOutside = (e: MouseEvent) => {
          if (chipRef.current && !chipRef.current.contains(e.target as Node)) {
            setIsSelected(false);
          }
        };
        document.addEventListener("mousedown", handleClickOutside);
        return () => document.removeEventListener("mousedown", handleClickOutside);
      }, [isSelected]);

      // Pending state
      if (isPending && pendingCallbackKey) {
        const callbacks = pendingCallbacks.get(pendingCallbackKey);
        return (
          <InlineChip ref={setRef}>
            {callbacks && (
              <InlineSearchPopover
                onSelect={(selectedWp) => {
                  callbacks.onSelect(selectedWp.id);
                  clearInlineWpCallbacks(pendingCallbackKey);
                }}
                onCancel={() => {
                  callbacks.onCancel();
                  clearInlineWpCallbacks(pendingCallbackKey);
                }}
              />
            )}
          </InlineChip>
        );
      }

      // Loading state
      if (wpid && workPackageResult.loading) {
        return (
          <InlineChip ref={setRef}>
            <ChipXXS><IdBadge>#{wpid}…</IdBadge></ChipXXS>
          </InlineChip>
        );
      }

      // Resolved chip
      if (wpid && wp) {
        return (
          <InlineChip
            ref={setRef}
            selected={isSelected}
            onClick={(e) => {
              e.preventDefault();
              e.stopPropagation();
              setIsSelected((prev) => !prev);
            }}
          >
            {size === "xxs" && <WpChipXXS wp={wp} />}
            {size === "xs"  && <WpChipXS  wp={wp} />}
            {size === "s"   && <WpChipS   wp={wp} />}

            {isSelected && (
              <WpOptionsPopover
                wp={wp}
                currentSize={size}
                instanceId={instanceId}
                onClose={() => setIsSelected(false)}
              />
            )}
          </InlineChip>
        );
      }

      // Error / unknown
      if (wpid) {
        return (
          <InlineChip ref={setRef} style={{ opacity: 0.6 }}>
            <ChipXXS><IdBadge>#{wpid}</IdBadge></ChipXXS>
          </InlineChip>
        );
      }

      return <InlineChip ref={setRef} />;
    },

    toExternalHTML: ({ inlineContent }) => {
      const { wpid } = inlineContent.props;
      if (!wpid || wpid.startsWith("pending:")) return <></>;
      return (
        <a href={`./wp/${wpid}`} target="_blank" rel="noopener noreferrer" data-inline-wp={wpid}>
          #{wpid}
        </a>
      );
    },
  }
);
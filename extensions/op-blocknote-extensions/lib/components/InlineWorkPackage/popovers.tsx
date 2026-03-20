import React, { useEffect, useRef, useState } from "react";
import styled from "styled-components";
import { useTranslation } from "react-i18next";
import type { WorkPackage } from "../../openProjectTypes";
import { linkToWorkPackage } from "../../services/openProjectApi";
import { useWorkPackageSearch } from "../../hooks/useWorkPackageSearch";
import { WorkPackageElement } from "../../elements/workPackageElement";
import type { InlineWpSize } from "./types";

// Search popover 

const SearchPopover = styled.div.attrs({ className: "op-bn-inline-search" })`
  position: absolute;
  z-index: 9999;
  background-color: var(--bn-colors-menu-background, #fff);
  box-shadow: 0 4px 16px rgba(0, 0, 0, 0.12);
  border-radius: 8px;
  padding: 8px 16px;
  width: 400px;
  top: 1.6em;
  left: 0;
`;

const SearchInput = styled.input`
  width: 100%;
  margin-top: 8px;
  padding: 8px 12px;
  border: 1px solid #ccc;
  border-radius: 6px;
  background: var(--bn-colors-menu-background, #fff);
  color: var(--bn-colors-editor-text, #333);
  font-size: 0.9em;
  box-sizing: border-box;
`;

const DropdownList = styled.div`
  overflow-y: auto;
  max-height: 240px;
  padding-top: 8px;
`;

const DropdownItem = styled.div<{ $selected: boolean }>`
  background-color: ${({ $selected }) =>
    $selected ? "var(--bn-colors-highlights-gray-background, #f0f0f0)" : "transparent"};
  border-radius: 6px;
  margin: 4px 0;
  padding: 0 8px;
  cursor: pointer;
`;

interface InlineSearchProps {
  onSelect: (wp: WorkPackage) => void;
  onCancel: () => void;
}

export const InlineSearchPopover = ({ onSelect, onCancel }: InlineSearchProps) => {
  const { t } = useTranslation();
  const inputRef = useRef<HTMLInputElement>(null);
  const isSelectingRef = useRef(false);
  const { searchQuery, setSearchQuery, searchResults } = useWorkPackageSearch();
  const [focusedIndex, setFocusedIndex] = useState(-1);
  const [isDropdownOpen, setIsDropdownOpen] = useState(false);

  useEffect(() => { requestAnimationFrame(() => inputRef.current?.focus()); }, []);

  const handleKeyDown = (e: React.KeyboardEvent<HTMLInputElement>) => {
    switch (e.key) {
      case "ArrowDown":
        e.preventDefault();
        if (!isDropdownOpen) setIsDropdownOpen(true);
        setFocusedIndex((p) => Math.min(p + 1, searchResults.length - 1));
        break;
      case "ArrowUp":
        e.preventDefault();
        setFocusedIndex((p) => Math.max(p - 1, 0));
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
            // Delay lets onMouseDown on a result fire before cancel
            setTimeout(() => {
              if (isSelectingRef.current) { isSelectingRef.current = false; return; }
              onCancel();
            }, 150);
          }}
        />
      </label>

      {isDropdownOpen && searchResults.length > 0 && (
        <DropdownList>
          {searchResults.slice(0, 5).map((wp, i) => (
            <DropdownItem
              key={wp.id}
              $selected={focusedIndex === i}
              onMouseDown={(e) => { e.preventDefault(); isSelectingRef.current = true; onSelect(wp); }}
              onMouseEnter={() => setFocusedIndex(i)}
            >
              <WorkPackageElement workPackage={wp} inDropdown="true" />
            </DropdownItem>
          ))}
        </DropdownList>
      )}
    </SearchPopover>
  );
};

// Options popover 

const Popover = styled.div.attrs({ className: "op-bn-inline-options" })`
  position: absolute;
  z-index: 9999;
  background-color: var(--bn-colors-menu-background, #fff);
  box-shadow: 0 4px 16px rgba(0,0,0,0.12), 0 1px 4px rgba(0,0,0,0.08);
  border-radius: 8px;
  padding: 4px;
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
  border-radius: 6px;
  padding: 5px 8px;
  cursor: pointer;
  font-size: 0.82em;
  color: ${({ $danger }) => ($danger ? "#c0392b" : "var(--bn-colors-editor-text, #333)")};
  display: flex;
  align-items: center;
  gap: 5px;
  line-height: 1;
  &:hover { background-color: var(--bn-colors-highlights-gray-background, #f5f5f5); }
  svg { flex-shrink: 0; }
`;

const Divider = styled.div`
  width: 1px; height: 18px;
  background: rgba(0,0,0,0.1);
  margin: 0 2px;
`;

const SizeMenu = styled.div`
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

const SizeBtn = styled.button<{ $active?: boolean }>`
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

// Inline SVG icons — no external dependency needed
const IcOpen = () => <svg width="13" height="13" viewBox="0 0 16 16" fill="none" stroke="currentColor" strokeWidth="1.8"><path d="M7 3H3a1 1 0 0 0-1 1v9a1 1 0 0 0 1 1h9a1 1 0 0 0 1-1V9"/><path d="M10 2h4v4"/><path d="M14 2 8 8"/></svg>;
const IcDelete = () => <svg width="13" height="13" viewBox="0 0 16 16" fill="none" stroke="currentColor" strokeWidth="1.8"><path d="M3 5h10M6 5V3h4v2M7 8v4M9 8v4M4 5l1 8h6l1-8"/></svg>;
const IcSize = () => <svg width="13" height="13" viewBox="0 0 16 16" fill="none" stroke="currentColor" strokeWidth="1.8"><rect x="2" y="5" width="12" height="6" rx="2"/><path d="M5 8h6"/></svg>;
const IcChevron = () => <svg width="10" height="10" viewBox="0 0 16 16" fill="none" stroke="currentColor" strokeWidth="2"><path d="M4 6l4 4 4-4"/></svg>;
const IcInline = () => <svg width="13" height="13" viewBox="0 0 16 16" fill="none" stroke="currentColor" strokeWidth="1.8"><rect x="1" y="6" width="14" height="4" rx="2"/></svg>;

const SIZE_OPTIONS: { value: InlineWpSize; label: string; desc: string }[] = [
  { value: "xxs", label: "XXS", desc: "ID" },
  { value: "xs", label: "XS",  desc: "ID, Type, Subject" },
  { value: "s", label: "S", desc: "ID, Type, Status, Subject" },
  { value: "m", label: "M", desc: "Block — full card" },
];

export interface WpOptionsProps {
  wp: WorkPackage;
  // `undefined` means this popover belongs to a block-level card 
  currentSize?: InlineWpSize;
  instanceId?: string;
  onClose: () => void;
}

export const WpOptionsPopover = ({ wp, currentSize, instanceId, onClose }: WpOptionsProps) => {
  const [showSizes, setShowSizes] = useState(false);
  const isBlock = currentSize === undefined;

  const dispatch = (event: string, detail: object) => {
    document.dispatchEvent(new CustomEvent(event, { detail }));
  };

  const resize = (size: InlineWpSize) => { dispatch("op-inline-wp-resize", { instanceId, wpid: wp.id, size }); setShowSizes(false); onClose(); };
  const remove = () => { dispatch("op-inline-wp-delete", { instanceId, wpid: wp.id }); onClose(); };
  const convertToInline = (size: InlineWpSize) => { dispatch("op-block-wp-to-inline", { wpid: wp.id, size }); setShowSizes(false); onClose(); };

  return (
    <Popover onMouseDown={(e) => e.stopPropagation()}>
      <PopBtn title="Open" onClick={(e) => { e.stopPropagation(); window.open(linkToWorkPackage(wp.id), "_blank", "noopener,noreferrer"); }}>
        <IcOpen /> Open
      </PopBtn>

      <Divider />

      <PopBtn title={isBlock ? "Convert to inline" : "Change size"} onClick={(e) => { e.stopPropagation(); setShowSizes((p) => !p); }}>
        {isBlock ? <IcInline /> : <IcSize />}
        {isBlock ? "Inline" : (currentSize ?? "s").toUpperCase()}
        <IcChevron />

        {showSizes && (
          <SizeMenu onMouseDown={(e) => e.stopPropagation()}>
            {isBlock && (
              <div style={{ padding: "4px 10px 6px", fontSize: "0.75em", opacity: 0.5, fontWeight: 600, textTransform: "uppercase", letterSpacing: "0.05em" }}>
                Convert to inline
              </div>
            )}
            {(isBlock ? SIZE_OPTIONS.filter((o) => o.value !== "m") : SIZE_OPTIONS).map((opt) => (
              <SizeBtn
                key={opt.value}
                $active={!isBlock && currentSize === opt.value}
                onMouseDown={(e) => { e.preventDefault(); e.stopPropagation(); isBlock ? convertToInline(opt.value) : resize(opt.value); }}
              >
                <strong style={{ minWidth: 28 }}>{opt.label}</strong>
                <span style={{ opacity: 0.6 }}>{opt.desc}</span>
              </SizeBtn>
            ))}
          </SizeMenu>
        )}
      </PopBtn>

      <Divider />

      <PopBtn $danger title="Remove" onClick={(e) => { e.stopPropagation(); remove(); }}>
        <IcDelete /> Remove
      </PopBtn>
    </Popover>
  );
};
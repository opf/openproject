import styled from "styled-components";
import { defaultVariables } from "../../services/colors";
import type { InlineWpSize } from "./types";
import {
  LinkExternalIcon,
  TrashIcon,
  ScreenFullIcon,
  ChevronDownIcon,
  ColumnsIcon,
} from "@primer/octicons-react";

// Search popover
export const SearchPopover = styled.div.attrs({ className: "op-bn-inline-search" })`
  ${defaultVariables}
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

export const SearchIconWrapper = styled.div`
  position: absolute;
  top: 50%;
  transform: translateY(-50%);
  left: var(--spacer-m);
  display: flex;
  align-items: center;
`;

export const SearchInput = styled.input`
  width: 100%;
  margin-top: var(--spacer-m);
  padding: var(--spacer-m) var(--spacer-l);
  border: 1px solid #ccc;
  border-radius: var(--bn-border-radius-small);
  background: var(--bn-colors-menu-background, #fff);
  color: var(--bn-colors-editor-text, #333);
  font-size: 0.9em;
  box-sizing: border-box;
`;

export const DropdownList = styled.div`
  overflow: hidden; 
  padding-top: var(--spacer-m);
`;

export const DropdownItem = styled.div<{ $selected: boolean }>`
  background-color: ${({ $selected }) =>
    $selected ? "var(--bn-colors-highlights-gray-background, #f0f0f0)" : "transparent"};
  border-radius: var(--bn-border-radius-small);
  margin: var(--spacer-s) 0;
  padding: 0 var(--spacer-m);
  cursor: pointer;
`;

// Options popover
export const Popover = styled.div.attrs({ className: "op-bn-inline-options" })`
  ${defaultVariables}
  position: absolute;
  z-index: 9999;
  background-color: var(--bn-colors-menu-background, #fff);
  box-shadow: var(--bn-shadow-medium);
  border-radius: var(--bn-border-radius-large);
  padding: var(--spacer-s);
  display: flex;
  align-items: center;
  gap: 2px;
  // Positioned above the chip with a small gap
  bottom: calc(100% + 6px);
  left: 0;
  white-space: nowrap;
`;

export const PopBtn = styled.button<{ $danger?: boolean }>`
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

export const Divider = styled.div`
  width: 1px; 
  height: 18px;
  background: var(--mantine-color-default-border);
  margin: 0 2px;
`;

export const SizeMenu = styled.div`
  position: absolute;
  top: calc(100% + var(--spacer-s));
  left: 0;
  // z-index must exceed Popover (9999) SizeMenu renders inside it 
  z-index: 10000;
  background: var(--bn-colors-menu-background, #fff);
  box-shadow: var(--bn-shadow-medium);
  border-radius: var(--bn-border-radius-large);
  padding: var(--spacer-s);
  min-width: 200px;
`;

export const SizeBtn = styled.button<{ $active?: boolean }>`
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

export const IcOpen = () => <LinkExternalIcon size={13} />;
export const IcDelete = () => <TrashIcon size={13} />;
export const IcSize = () => <ScreenFullIcon size={13} />;
export const IcChevron = () => <ChevronDownIcon size={10} />;
export const IcInline = () => <ColumnsIcon size={13} />;

export const SIZE_OPTIONS: { value: InlineWpSize; label: string; desc: string }[] = [
  { value: "xxs", label: "XXS", desc: "ID" },
  { value: "xs",  label: "XS",  desc: "ID, Type, Subject" },
  { value: "s",   label: "S",   desc: "ID, Type, Status, Subject" },
  { value: "m",   label: "M",   desc: "Block — full card" },
];
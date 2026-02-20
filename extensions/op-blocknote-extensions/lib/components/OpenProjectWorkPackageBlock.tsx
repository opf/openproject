import {
  BlockNoteEditor,
  createBlockConfig,
  createBlockSpec,
} from "@blocknote/core";
import { insertOrUpdateBlockForSlashMenu } from "@blocknote/core/extensions";
import { createReactBlockSpec } from "@blocknote/react";
import React, { useEffect, useRef, useState } from "react";
import { useWorkPackage } from "../hooks/useWorkPackage";
import { useWorkPackageSearch } from "../hooks/useWorkPackageSearch";
import type { WorkPackage } from "../openProjectTypes";
import { linkToWorkPackage } from "../services/openProjectApi";
import { useColors } from "../services/colors";
import { getAliases } from "../services/slashMenuAliases";
import { useTranslation } from "react-i18next";
import i18n from "../services/i18n.ts";
import { LinkIcon, SearchIcon } from "@primer/octicons-react";
import { WorkPackageElement } from "../elements/workPackageElement";
import { UnavailableWorkPackageElement } from "../elements/unavailableWorkPackageElement";
import styled from "styled-components";

const Block = styled.div.attrs({ className: "op-bn-extensions" })<{
  hasWp: boolean;
}>`
  --highlight-wp-background: var(--bn-colors-highlights-gray-background);
  [data-color-scheme="dark"] & {
    --highlight-wp-background: var(--bn-colors-disabled-text);
  }
  --spacer-s: 4px;
  --spacer-m: 8px;
  --spacer-l: 12px;
  --spacer-xl: 16px;
`;

const Search = styled.div.attrs({ className: "op-bn-search" })`
  position: relative;
  padding: var(--spacer-m) var(--spacer-xl);
  box-shadow: var(--bn-shadow-medium);
  border-radius: var(--bn-border-radius-large);
  width: 100%;
  background: var(--bn-colors-editor-background);
  @media (min-width: 1120px) {
    width: 500px;
  }
`;

const SearchLabel = styled.label.attrs({ className: "op-bn-search--label" })`
  font-weight: normal !important;
`;

const SearchInputWrapper = styled.div.attrs({
  className: "op-bn-search--input-wrapper",
})`
  position: relative;
  margin-top: var(--spacer-m);
`;

const SearchIconWrapper = styled.div.attrs({
  className: "op-bn-search--icon-wrapper",
})`
  position: absolute;
  top: 50%;
  transform: translateY(-50%);
  padding-left: var(--spacer-m);
`;

const SearchInput = styled.input.attrs({ className: "op-bn-search--input" })`
  width: 100%;
  padding: var(--spacer-m) var(--spacer-l);
  padding-left: 30px !important; // Hardcoded padding for icon
  border: 1px solid var(--bn-colors-border);
  border-radius: var(--bn-border-radius-small);
  background: var(--bn-colors-editor-background);
  color: var(--bn-colors-editor-text);

  &:focus {
    outline: 2px solid var(--bn-colors-border);
  }
`;

const Dropdown = styled.div.attrs({ className: "op-bn-dropdown" })`
  background-color: var(--bn-colors-menu-background);
  overflow-y: auto;
  max-height: 300px;
  padding-top: var(--spacer-m);
  margin: 0 -(var(--spacer-m));
`;

const DropdownOption = styled.div.attrs({
  className: "op-bn-dropdown--option",
})<{ selected: boolean }>`
  background-color: ${({ selected }) =>
    selected ? "var(--highlight-wp-background)" : "transparent"};
  border: none;
  border-radius: var(--bn-border-radius-small);
  margin: var(--spacer-s) var(--spacer-m);
  padding: var(--spacer-s) var(--spacer-m);
  cursor: pointer;
`;

interface BlockProps {
  id: string;
  props: {
    wpid?: number;
    initialized?: boolean;
  };
}

const OpenProjectWorkPackageBlockComponent = ({
  block,
  editor,
}: {
  block: BlockProps;
  editor: BlockNoteEditor<any>;
}) => {
  const { t } = useTranslation();
  const inputRef = useRef<HTMLInputElement>(null);
  const dropdownRef = useRef<HTMLDivElement>(null);
  const isSelectingRef = useRef(false);
  useColors(); // hook for syncing colors with editor

  const { searchQuery, setSearchQuery, searchResults } = useWorkPackageSearch();
  const [selectedWorkPackage, setSelectedWorkPackage] =
    useState<WorkPackage | null>(null);
  const [isDropdownOpen, setIsDropdownOpen] = useState(false);
  const [focusedResultIndex, setFocusedResultIndex] = useState(-1);
  const [isActive, setIsActive] = useState(false);

  const workPackageResult = useWorkPackage(block.props.wpid);

  useEffect(() => {
    // Sync selectedWorkPackage when result updates
    if (!workPackageResult.error && workPackageResult.workPackage) {
      setSelectedWorkPackage(workPackageResult.workPackage);
    }
  }, [workPackageResult.error, workPackageResult.workPackage]);

  useEffect(() => {
    // Direct access to _tiptapEditor
    const tiptap = (editor as any)._tiptapEditor;
    if (!tiptap) return;

    const updateActiveState = () => {
      const pos = editor.getTextCursorPosition();
      setIsActive(pos?.block?.id === block.id);
    };

    tiptap.on("selectionUpdate", updateActiveState);
    updateActiveState();

    return () => {
      tiptap.off("selectionUpdate", updateActiveState);
    };
  }, [editor, block.id]);

  useEffect(() => {
    // Using requestAnimationFrame for focus, could be race condition
    if (
      !block.props.wpid &&
      !block.props.initialized &&
      isActive &&
      inputRef.current
    ) {
      requestAnimationFrame(() => {
        inputRef.current?.focus();
      });
    }
  }, [block.props.wpid, block.props.initialized, isActive]);

  const handleSelectWorkPackage = (workPackage: WorkPackage) => {
    isSelectingRef.current = true;

    setSelectedWorkPackage(workPackage);
    setSearchQuery("");
    setIsDropdownOpen(false);
    setFocusedResultIndex(-1);

    editor.updateBlock(block, {
      props: {
        ...block.props,
        wpid: workPackage.id,
        initialized: true,
      },
    });

    editor.focus(); // Focus editor after selection
  };

  const handleKeyDown = (e: React.KeyboardEvent) => {
    if (e.key === "ArrowDown") {
      e.preventDefault();
      if (!isDropdownOpen) setIsDropdownOpen(true);
      setFocusedResultIndex((prev) =>
        prev < searchResults.length - 1 ? prev + 1 : prev,
      ); // tightly coupled to searchResults length
    } else if (e.key === "ArrowUp") {
      e.preventDefault();
      setFocusedResultIndex((prev) => (prev > 0 ? prev - 1 : 0));
    } else if (e.key === "Enter") {
      if (focusedResultIndex >= 0 && searchResults[focusedResultIndex]) {
        e.preventDefault();
        handleSelectWorkPackage(searchResults[focusedResultIndex]);
      }
    } else if (e.key === "Escape") {
      editor.updateBlock(block, {
        props: { ...block.props, initialized: true },
      });
      editor.focus();
    }
  };

  const disableFocus = block.props.initialized && !block.props.wpid;

  return (
    <Block
      hasWp={!!block.props.wpid}
      tabIndex={disableFocus ? -1 : 0} // tabIndex toggle could affect accessibility
      style={disableFocus ? { pointerEvents: "none" } : undefined}
    >
      <div contentEditable={false}>
        {!block.props.wpid && !block.props.initialized && isActive && (
          <Search>
            <SearchLabel>
              {t("search.label")}
              <SearchInputWrapper>
                <SearchIconWrapper>
                  <SearchIcon size={18} />
                </SearchIconWrapper>
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
                      setIsDropdownOpen(false);
                      setFocusedResultIndex(-1);
                      setIsActive(false);

                      // If we just selected an item do nothing
                      if (isSelectingRef.current) {
                        isSelectingRef.current = false;
                        return;
                      }

                      // Remove only if truly empty
                      if (!block.props.wpid) {
                        editor.removeBlocks([block.id]);
                      }
                    }, 100);
                  }}
                />
              </SearchInputWrapper>
            </SearchLabel>

            {isDropdownOpen && searchResults.length > 0 && (
              <Dropdown ref={dropdownRef}>
                {searchResults.slice(0, 5).map((wp, index) => (
                  <DropdownOption
                    key={wp.id}
                    selected={focusedResultIndex === index}
                    onMouseDown={(e) => {
                      e.preventDefault(); // prevent input blur
                      handleSelectWorkPackage(wp);
                    }}
                    onMouseEnter={() => setFocusedResultIndex(index)}
                  >
                    <WorkPackageElement workPackage={wp} inDropdown="true" />
                  </DropdownOption>
                ))}
              </Dropdown>
            )}
          </Search>
        )}

        {block.props.wpid && (
          <>
            {!selectedWorkPackage && workPackageResult.loading && (
              <UnavailableWorkPackageElement
                header={t("unavailableWorkPackage.loading.header")}
                message={t("unavailableWorkPackage.loading.message")}
              />
            )}
            {selectedWorkPackage && (
              <WorkPackageElement workPackage={selectedWorkPackage} linkTitle />
            )}
          </>
        )}
      </div>
    </Block>
  );
};

// Config with proper propSchema
export const openprojectWorkPackageBlockConfig = createBlockConfig((() => ({
  type: "openProjectWorkPackage",
  propSchema: {
    wpid: { default: undefined, type: "number" },
    initialized: { default: false, type: "boolean" },
  },
  content: "none",
  isSelectable: false,
})) as unknown as ReturnType<typeof createBlockConfig>);

export const openProjectWorkPackageBlockSpec = createReactBlockSpec(
  openprojectWorkPackageBlockConfig,
  {
    render: (props) => (
      <OpenProjectWorkPackageBlockComponent
        block={props.block}
        editor={props.editor as any}
      />
    ),
  },
);

export const openProjectWorkPackageStaticBlockSpec = createBlockSpec(
  openprojectWorkPackageBlockConfig,
  {
    render: (block) => {
      const wpid = block.props.wpid;
      const anchor = document.createElement("a");
      anchor.href = linkToWorkPackage(wpid);
      anchor.textContent = `#${wpid}`;
      return { dom: anchor, contentDOM: anchor };
    },
  },
);

export const openProjectWorkPackageSlashMenu = (editor: any) => ({
  title: i18n.t("slashMenu.title"),
  onItemClick: () => {
    const insertedBlock = insertOrUpdateBlockForSlashMenu(editor, {
      type: "openProjectWorkPackage",
    });
    requestAnimationFrame(() => {
      // ensure cursor is placed in newly inserted block
      if (insertedBlock?.id) {
        editor.setTextCursorPosition(insertedBlock.id, "start");
        editor.focus();
      }
    });
  },
  aliases: [...getAliases()],
  group: "OpenProject",
  icon: <LinkIcon size={18} />,
  subtext: i18n.t("slashMenu.subtext"),
});

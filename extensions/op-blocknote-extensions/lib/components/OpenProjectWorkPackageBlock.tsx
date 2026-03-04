import type { DefaultBlockSchema } from "@blocknote/core";
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
  // Added hasWp prop to be able to style the block if WP is present
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
  border: 1px solid #ccc;
  border-radius: var(--bn-border-radius-small);
`;

const Dropdown = styled.div.attrs({
  className: "op-bn-dropdown"
})`
  background-color: var(--bn-colors-menu-background);
  overflow-y: auto;
  padding-top: var(--spacer-m);
  margin: 0 -(var(--spacer-m));
`;

const DropdownOption = styled.div.attrs({
  className: "op-bn-dropdown--option"
})<{ selected: boolean }>`
  background-color: ${({ selected }) =>
    selected
      ? "var(--highlight-wp-background)"
      : "var(--bn-colors-menu-background)"};
  border: none;
  border-radius: var(--bn-border-radius-small);
  margin: var(--spacer-s) 0;
  padding: 0 var(--spacer-m);
  cursor: pointer;
`;

interface BlockProps {
  id: string;
  props: {
    wpid?: number;
    initialized?: boolean; // to know if the block is already initialized
  };
}

//function to handle a click on a slash menu item
function handleOpenProjectWorkPackageClick(editor: BlockNoteEditor<any>) {
  const insertedBlock = insertOrUpdateBlockForSlashMenu(editor, {
    type: "openProjectWorkPackage",
  });

  requestAnimationFrame(() => {
    if (!insertedBlock?.id) return;

    editor.setTextCursorPosition(insertedBlock.id, "start");
    editor.focus();

    const [newTextBlock] = editor.insertBlocks(
      [{ type: "text", content: "" }],
      insertedBlock.id
    );

    if (newTextBlock?.id) {
      requestAnimationFrame(() => {
        editor.setTextCursorPosition(newTextBlock.id, "start");
        editor.focus();
      });
    }
  });
}

const OpenProjectWorkPackageBlockComponent = ({
  block,
  editor,
}: {
  block: BlockProps;
  editor: BlockNoteEditor<
    DefaultBlockSchema & {
      openProjectWorkPackage: ReturnType<typeof openprojectWorkPackageBlockConfig>;
    }
  >;
}) => {
  const { t } = useTranslation();
  const inputRef = useRef<HTMLInputElement>(null);
  const dropdownRef = useRef<HTMLDivElement>(null);
  const isSelectingRef = useRef(false); // to follow the WP selection from the dropdown

  // Fetch and cache colors.
  // The hook handles triggering re-renders when data arrives.
  useColors();

  const { searchQuery, setSearchQuery, searchResults } =
    useWorkPackageSearch();

  const [isDropdownOpen, setIsDropdownOpen] = useState(false);
  const [focusedResultIndex, setFocusedResultIndex] = useState(-1);
  const [isActive, setIsActive] = useState(false);

  // use a single source of truth — result from useWorkPackage.
  const workPackageResult = useWorkPackage(block.props.wpid); 

  const selectedWorkPackage = workPackageResult.workPackage;

  useEffect(() => {
    // accessing private tiptap instance until public API is available
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
    // Autofocus only when the block is active and not yet initialized
    if (
      !block.props.wpid &&
      !block.props.initialized &&
      isActive &&
      inputRef.current
    ) {
      // use requestAnimationFrame to wait for React 
      // to commit and update the internal state
      // of the BlockNote before focusing.
      requestAnimationFrame(() => {
        inputRef.current?.focus();
      });
    }
  }, [block.props.wpid, block.props.initialized, isActive]);

  const handleSelectWorkPackage = (workPackage: WorkPackage) => {
    isSelectingRef.current = true; // checkbox so that onBlur does not remove the block

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

    requestAnimationFrame(() => {
      // move the cursor to the next block after selecting WP
      moveCursorToNextBlock(editor, block.id);
    });
  };

  const handleKeyDown = (e: React.KeyboardEvent) => {
    if (e.key === "ArrowDown") {
      e.preventDefault();
      if (!isDropdownOpen) setIsDropdownOpen(true);
      setFocusedResultIndex((prev) =>
        prev < searchResults.length - 1 ? prev + 1 : prev
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
        props: { ...block.props, initialized: true }, // close the dropdown, fix initialized
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
              <Dropdown
                ref={dropdownRef}
                role="listbox"
                aria-label={t("search.dropdownAriaLabel")}
              >
                {searchResults.slice(0, 5).map((wp, index) => (
                  <DropdownOption
                    key={wp.id}
                    role="option"
                    aria-selected={focusedResultIndex === index}
                    tabIndex={0}
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
            {workPackageResult.loading && (
              <UnavailableWorkPackageElement
                header={t("unavailableWorkPackage.loading.header")}
                message={t("unavailableWorkPackage.loading.message")}
              />
            )}

            {!workPackageResult.loading && workPackageResult.error && (
              <UnavailableWorkPackageElement
                header={t("unavailableWorkPackage.error.header")}
                message={t("unavailableWorkPackage.error.message")}
              />
            )}

            {!workPackageResult.loading &&
              !workPackageResult.error &&
              workPackageResult.unauthorized && (
                <UnavailableWorkPackageElement
                  header={t(
                    "unavailableWorkPackage.unauthorized.header"
                  )}
                  message={t(
                    "unavailableWorkPackage.unauthorized.message"
                  )}
                />
              )}

            {!workPackageResult.loading &&
              !workPackageResult.error &&
              !workPackageResult.unauthorized &&
              selectedWorkPackage && (
                <WorkPackageElement
                  workPackage={selectedWorkPackage}
                  linkTitle
                />
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
  }
);

export const openProjectWorkPackageStaticBlockSpec = createBlockSpec(
  openprojectWorkPackageBlockConfig,
  {
    render: (block) => {
      const wpid = block.props.wpid;
      const href = linkToWorkPackage(wpid);

      /*
      Create a wrapper element.
      This is done for a stable DOM structure,
      because <a> as a root block element
      may not be serialized correctly in the clipboard.
       */
      const wrapper = document.createElement("span");

      const anchor = document.createElement("a");
      anchor.href = href;
      anchor.target = "_blank";
      anchor.rel = "noopener noreferrer";
      anchor.textContent = `#${wpid}`;

      wrapper.appendChild(anchor);

      return {
        dom: wrapper,
        contentDOM: wrapper,
      };
    },
  }
);

export const openProjectWorkPackageSlashMenu = (editor: BlockNoteEditor<any>) => ({
  title: i18n.t("slashMenu.title"),
  onItemClick: () => handleOpenProjectWorkPackageClick(editor),
  aliases: [...getAliases()],
  group: "OpenProject",
  icon: <LinkIcon size={18} />,
  subtext: i18n.t("slashMenu.subtext"),
});

function moveCursorToNextBlock(
  editor: BlockNoteEditor<any>,
  blockId: string
) {
  editor.focus();
  editor.setTextCursorPosition(blockId, "end");

  const cursor = editor.getTextCursorPosition();

  if (!cursor?.nextBlock && cursor?.block) {
    editor.insertBlocks([{ type: "text", content: "" }], cursor.block.id);
  }

  const updatedCursor = editor.getTextCursorPosition();

  if (updatedCursor?.nextBlock) {
    editor.setTextCursorPosition(updatedCursor.nextBlock.id, "start");
  }
}
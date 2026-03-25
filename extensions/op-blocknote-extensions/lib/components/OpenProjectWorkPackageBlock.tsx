import type { DefaultBlockSchema } from "@blocknote/core";
import {
  BlockNoteEditor,
  createBlockConfig,
  createBlockSpec,
} from "@blocknote/core";
import { createReactBlockSpec } from "@blocknote/react";
import { useEffect, useRef, useState } from "react";
import { useWorkPackage } from "../hooks/useWorkPackage";
import type { WorkPackage } from "../openProjectTypes";
import { linkToWorkPackage } from "../services/openProjectApi";
import { useColors } from "../services/colors";
import { useTranslation } from "react-i18next";
import { WorkPackageElement } from "../elements/workPackageElement";
import { UnavailableWorkPackageElement } from "../elements/unavailableWorkPackageElement";
import styled from "styled-components";
import { SearchDropdown } from "./SearchDropdown";
import { WpOptionsPopover } from "../components/InlineWorkPackage/popovers";
import type { InlineWpSize } from "../components/InlineWorkPackage/types";
import { wpBridge } from "../services/wpBridge";

const Block = styled.div.attrs({ className: "op-bn-extensions" })<{
  // Added hasWp prop to be able to style the block if WP is present
  hasWp: boolean;
}>`
  --highlight-wp-background: var(--bn-colors-highlights-gray-background);
  [data-color-scheme="dark"] & {
    --highlight-wp-background: var(--bn-colors-disabled-text);
  }
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

interface BlockProps {
  id: string;
  props: {
    wpid?: number;
    initialized?: boolean; // to know if the block is already initialized
  };
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
  const cardRef = useRef<HTMLDivElement>(null);
  // Fetch and cache colors.
  // The hook handles triggering re-renders when data arrives.
  useColors();

  const [isActive, setIsActive] = useState(false);
  const [isOptionsOpen, setIsOptionsOpen] = useState(false);

  // use a single source of truth — result from useWorkPackage.
  const workPackageResult = useWorkPackage(block.props.wpid); 
  const selectedWorkPackage = workPackageResult.workPackage;

  const handleSelectWorkPackage = (wp: WorkPackage) => {
    editor.updateBlock(block, {
      props: { ...block.props, wpid: wp.id, initialized: true },
    });
    requestAnimationFrame(() => moveCursorToNextBlock(editor, block.id));
  };

  useEffect(() => {
    // accessing private tiptap instance until public API is available
    const tiptap = (editor as any)._tiptapEditor;
    if (!tiptap) return;

    const updateActiveState = () => {
      setIsActive(editor.getTextCursorPosition()?.block?.id === block.id);
    };

    tiptap.on("selectionUpdate", updateActiveState);
    updateActiveState();
    return () => { tiptap.off("selectionUpdate", updateActiveState); };
  }, [editor, block.id]);

  // Close options popover on outside click
  useEffect(() => {
    if (!isOptionsOpen) return;
    const handleClickOutside = (e: MouseEvent) => {
      if (cardRef.current && !cardRef.current.contains(e.target as Node)) {
        setIsOptionsOpen(false);
      }
    };
    document.addEventListener("mousedown", handleClickOutside);
    return () => document.removeEventListener("mousedown", handleClickOutside);
  }, [isOptionsOpen]);

  const handleConvertToInline = (size: InlineWpSize) => {
    if (!selectedWorkPackage) return;
    wpBridge.convertToInline({ wpid: selectedWorkPackage.id, size, blockId: block.id });
  };

  const handleRemove = () => {
    editor.removeBlocks([block]);
  };

  const disableFocus = block.props.initialized && !block.props.wpid;

  return (
    <Block
      hasWp={!!block.props.wpid}
      tabIndex={disableFocus ? -1 : 0}
      style={disableFocus ? { pointerEvents: "none" } : undefined}
    >
      <div contentEditable={false} style={{ userSelect: "none" }}>
        {!block.props.wpid && !block.props.initialized && isActive && (
          <Search>
            <SearchLabel>
              {t("search.label")}
              <SearchDropdown
                autoFocus
                onSelect={handleSelectWorkPackage}
                onCancel={() => {
                  editor.updateBlock(block, {
                    props: { ...block.props, initialized: true },
                  });
                  editor.focus();
                }}
              />
            </SearchLabel>
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
            {!workPackageResult.loading && !workPackageResult.error && workPackageResult.unauthorized && (
              <UnavailableWorkPackageElement
                header={t("unavailableWorkPackage.unauthorized.header")}
                message={t("unavailableWorkPackage.unauthorized.message")}
              />
            )}
            {!workPackageResult.loading &&
              !workPackageResult.error &&
              !workPackageResult.unauthorized &&
              selectedWorkPackage && (
                <div style={{ position: "relative", display: "inline-block" }}>
                  <WorkPackageElement
                    ref={cardRef}
                    workPackage={selectedWorkPackage}
                    linkTitle
                    onClick={(e) => {
                      e.stopPropagation();
                      setIsOptionsOpen((prev) => !prev);
                    }}
                  />
                  {isOptionsOpen && (
                    <WpOptionsPopover
                      wp={selectedWorkPackage}
                      currentSize={undefined}
                      instanceId={undefined}
                      onClose={() => setIsOptionsOpen(false)}
                      onConvertToInline={handleConvertToInline}
                      onRemove={handleRemove}
                    />
                  )}
                </div>
              )}
          </>
        )}
      </div>
    </Block>
  );
};

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
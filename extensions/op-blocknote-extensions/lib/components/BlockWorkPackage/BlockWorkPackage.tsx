import { BlockNoteEditor } from "@blocknote/core";
import { useEffect, useRef, useState } from "react";
import styled from "styled-components";
import { useTranslation } from "react-i18next";
import { useWorkPackage } from "../../hooks/useWorkPackage";
import { useColors } from "../../services/colors";
import { wpBridge } from "../../services/wpBridge";
import type { WorkPackage } from "../../openProjectTypes";
import type { InlineWpSize } from "../InlineWorkPackage/types";
import { BlockCard } from "./BlockCard";
import { UnavailableCard } from "../WorkPackage/UnavailableCard";
import { WpOptionsPopover } from "../WorkPackage/OptionsPopover";
import { SearchContainer, SearchLabel } from "../Search/SearchContainer";
import { SearchDropdown } from "../Search/SearchDropdown";

const Block = styled.div.attrs({ className: "op-bn-extensions" })`
  --highlight-wp-background: var(--bn-colors-highlights-gray-background);
  [data-color-scheme="dark"] & {
    --highlight-wp-background: var(--bn-colors-disabled-text);
  }
`;

const BlockCardWrapper = styled.div`
  position: relative;
  display: inline-block;
`;

interface BlockProps {
  id: string;
  props: {
    wpid?: number;
    initialized?: boolean;
  };
}

export const BlockWorkPackageComponent = ({
  block,
  editor,
}: {
  block: BlockProps;
  editor: BlockNoteEditor<any>;
}) => {
  const { t } = useTranslation();
  const cardRef = useRef<HTMLDivElement>(null);
  // Fetch and cache colors.
  // The hook handles triggering re-renders when data arrives.
  useColors();

  const [isActive, setIsActive] = useState(false);
  const [isOptionsOpen, setIsOptionsOpen] = useState(false);

  // Use a single source of truth — result from useWorkPackage.
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
      tabIndex={disableFocus ? -1 : 0}
      style={disableFocus ? { pointerEvents: "none" } : undefined}
    >
      <div contentEditable={false} style={{ userSelect: "none" }}>
        {!block.props.wpid && !block.props.initialized && isActive && (
          <SearchContainer>
            <SearchLabel>
              {t("search.label")}
            </SearchLabel>
            <SearchDropdown
              autoFocus
              onSelect={handleSelectWorkPackage}
              onCancel={() => {
                editor.updateBlock(block, {
                  props: { ...block.props, initialized: true },
                });
                editor.focus();
              }}
              renderItem={(wp) => <BlockCard workPackage={wp} inDropdown />}
            />
          </SearchContainer>
        )}

        {block.props.wpid && (
          <>
            {workPackageResult.loading && (
              <UnavailableCard
                header={t("unavailableWorkPackage.loading.header")}
                message={t("unavailableWorkPackage.loading.message")}
              />
            )}
            {!workPackageResult.loading && workPackageResult.error && (
              <UnavailableCard
                header={t("unavailableWorkPackage.error.header")}
                message={t("unavailableWorkPackage.error.message")}
              />
            )}
            {!workPackageResult.loading && !workPackageResult.error && workPackageResult.unauthorized && (
              <UnavailableCard
                header={t("unavailableWorkPackage.unauthorized.header")}
                message={t("unavailableWorkPackage.unauthorized.message")}
              />
            )}
            {!workPackageResult.loading &&
              !workPackageResult.error &&
              !workPackageResult.unauthorized &&
              selectedWorkPackage && (
                <BlockCardWrapper>
                  <BlockCard
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
                </BlockCardWrapper>
              )}
          </>
        )}
      </div>
    </Block>
  );
};

function moveCursorToNextBlock(editor: BlockNoteEditor<any>, blockId: string) {
  editor.focus();
  editor.setTextCursorPosition(blockId, "end");

  const cursor = editor.getTextCursorPosition();

  if (!cursor?.nextBlock && cursor?.block) {
    editor.insertBlocks([{ type: "paragraph", content: [] }], cursor.block.id, "after");
  }

  const updatedCursor = editor.getTextCursorPosition();
  if (updatedCursor?.nextBlock) {
    editor.setTextCursorPosition(updatedCursor.nextBlock.id, "start");
  }
}
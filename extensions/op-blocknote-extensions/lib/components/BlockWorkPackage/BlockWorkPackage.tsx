import { BlockNoteEditor } from "@blocknote/core";
import { useCallback, useEffect, useRef, useState } from "react";
import styled from "styled-components";
import { useTranslation } from "react-i18next";
import { useWorkPackage } from "../../hooks/useWorkPackage";
import { useColors } from "../../services/colors";
import { wpBridge } from "../../services/wpBridge";
import type { WorkPackage } from "../../openProjectTypes";
import type { InlineWpSize, BlockWpSize } from "../WorkPackage/types";
import { BlockCard } from "./BlockCard";
import { UnavailableCard } from "../WorkPackage/UnavailableCard";
import { WpOptionsPopover } from "../WorkPackage/OptionsPopover";
import { SearchContainer, SearchLabel } from "../Search/SearchContainer";
import { SearchDropdown } from "../Search/SearchDropdown";
import { defaultWpVariables } from "../WorkPackage/atoms";
import { formatWorkPackageId } from "../../utils/id";

const Block = styled.div.attrs({ className: "op-bn-extensions" })`
  ${defaultWpVariables}
  background-color: var(--op-chip-bg);
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
    size?: BlockWpSize;
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

  const workPackageResult = useWorkPackage(block.props.wpid);
  const selectedWorkPackage = workPackageResult.workPackage;

  const cardSize: BlockWpSize = block.props.size ?? "m";

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

  const handleCopy = useCallback(
    (e: ClipboardEvent) => {
      if (!isOptionsOpen || !block.props.wpid) return;

      e.preventDefault();
      e.stopPropagation();

      const wpid = block.props.wpid;
      const formattedId = formatWorkPackageId(selectedWorkPackage?.displayId ?? String(wpid));

      e.clipboardData?.setData("text/plain", formattedId);
      e.clipboardData?.setData(
        "text/html",
        `<div data-block-content-type="openProjectWorkPackageBlock" data-wpid="${wpid}" data-size="${cardSize}" data-initialized="true">${formattedId}</div>`,
      );
    },
    [isOptionsOpen, block.props.wpid, cardSize, selectedWorkPackage],
  );

  useEffect(() => {
    if (!isOptionsOpen) return;

    // Chrome doesn't expose clipboardData on copy events that bubble past a
    // shadow boundary - attach to the nearest root to get a writable event.
    const root = (cardRef.current?.getRootNode() ?? document) as Document | ShadowRoot;
    root.addEventListener("copy", handleCopy as EventListener);
    return () => root.removeEventListener("copy", handleCopy as EventListener);
  }, [isOptionsOpen, handleCopy]);

  const handleConvertToInline = (size: InlineWpSize) => {
    if (!selectedWorkPackage) return;
    wpBridge.convertToInline({ wpid: selectedWorkPackage.id, size, blockId: block.id });
  };

  const handleResizeBlock = (size: BlockWpSize) => {
    editor.updateBlock(block, {
      props: { ...block.props, size },
    });
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
                    size={cardSize}
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
                      currentBlockSize={cardSize}
                      instanceId={undefined}
                      anchorEl={cardRef.current}
                      onClose={() => setIsOptionsOpen(false)}
                      onConvertToInline={handleConvertToInline}
                      onConvertToBlock={handleResizeBlock}
                      onResizeBlock={handleResizeBlock}
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
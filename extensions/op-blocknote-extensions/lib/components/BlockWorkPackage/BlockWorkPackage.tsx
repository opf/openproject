import { BlockNoteEditor, SideMenuExtension } from "@blocknote/core";
import { useEffect, useRef, useState } from "react";
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
import { moveCursorAfterBlock } from "../../utils/cursor";

const Block = styled.div.attrs({ className: "op-bn-extensions" })`
  ${defaultWpVariables}
  background-color: var(--op-chip-bg);  
  user-select: all; 
  border-radius: var(--bn-border-radius);
`;

const BlockCardWrapper = styled.div`
  position: relative;
  display: inline-block;
`;

type SideMenuInstance = NonNullable<ReturnType<ReturnType<typeof SideMenuExtension>>>;

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
    requestAnimationFrame(() => moveCursorAfterBlock(editor, block.id));
  };

  // Delegate the drag to the same mechanism the side menu uses internally,
  // so dragging the block directly behaves identically to dragging via the handle.
  const handleBlockDragStart = (e: React.DragEvent) => {
    const sideMenu = editor.extensions.get("sideMenu") as SideMenuInstance | undefined;
    sideMenu?.blockDragStart(e.nativeEvent, block as any);
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
      draggable="true"
      onDragStart={handleBlockDragStart}
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


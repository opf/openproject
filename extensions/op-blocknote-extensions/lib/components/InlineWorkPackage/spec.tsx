import { createReactInlineContentSpec } from "@blocknote/react";
import { useEffect, useRef, useState } from "react";
import styled from "styled-components";
import { useWorkPackage } from "../../hooks/useWorkPackage";
import { useColors } from "../../services/colors";
import { TOKEN } from "./tokens";
import { ChipBase, IdAtom } from "./atoms";
import { WpChipXXS, WpChipXS, WpChipS } from "./chips";
import { InlineSearchPopover, WpOptionsPopover } from "./popovers";
import { getInlineWpCallbacks, clearInlineWpCallbacks } from "./callbacks";
import type { InlineWpSize } from "./types";

// Outer chip wrapper 
const InlineChip = styled.span.attrs({ 
  className: "op-bn-inline-wp",
  contentEditable: false,
})<{
  selected?: boolean;
}>`
  display: inline-flex;
  align-items: center;
  vertical-align: middle;
  cursor: pointer;
  user-select: none;
  border-radius: ${TOKEN.chip.radius};
  outline: ${({ selected }) => (selected ? TOKEN.focusOutline : "none")};
  outline-offset: 1px;
  box-shadow: ${({ selected }) => (selected ? TOKEN.focusShadow : "none")};
  position: relative;
  max-width: 100%;
`;

// Spec

export const inlineWorkPackageSpec = createReactInlineContentSpec(
  {
    type: "inlineWorkPackage" as const,
    propSchema: {
      wpid: { default: "" },
      instanceId: { default: "" },
      size: { default: "s" },
    },
    content: "none",
  },
  {
    render: ({ inlineContent, contentRef }) => {
      const rawWpid = inlineContent.props.wpid;
      const size = (inlineContent.props.size ?? "s") as InlineWpSize;
      const instanceId = inlineContent.props.instanceId;

      const isPending = rawWpid.startsWith("pending:");
      const pendingCallbackKey = isPending ? rawWpid.slice("pending:".length) : null;
      const wpid = !isPending && rawWpid ? Number(rawWpid) : undefined;

      useColors();

      const { workPackage: wp, loading } = useWorkPackage(wpid);

      const [isSelected, setIsSelected] = useState(false);
      const chipRef = useRef<HTMLElement | null>(null);

      const setRef = (node: HTMLElement | null) => {
        chipRef.current = node;
        contentRef(node);
      };

      // Close the options popover when the user clicks outside the chip
      useEffect(() => {
        if (!isSelected) return;
        const onClickOutside = (e: MouseEvent) => {
          if (chipRef.current && !chipRef.current.contains(e.target as Node)) {
            setIsSelected(false);
          }
        };
        document.addEventListener("mousedown", onClickOutside);
        return () => document.removeEventListener("mousedown", onClickOutside);
      }, [isSelected]);

      // Pending: waiting for user to pick a WP via search
      if (isPending && pendingCallbackKey) {
        const cbs = getInlineWpCallbacks(pendingCallbackKey);
        return (
          <InlineChip ref={setRef}>
            {cbs && (
              <InlineSearchPopover
                onSelect={(selectedWp) => { cbs.onSelect(selectedWp.id); clearInlineWpCallbacks(pendingCallbackKey); }}
                onCancel={() => { cbs.onCancel(); clearInlineWpCallbacks(pendingCallbackKey); }}
              />
            )}
          </InlineChip>
        );
      }

      // Loading 
      if (wpid && loading) {
        return <InlineChip ref={setRef}><ChipBase><IdAtom>#{wpid}…</IdAtom></ChipBase></InlineChip>;
      }

      // Resolved 
      if (wpid && wp) {
        return (
          <InlineChip
            ref={setRef}
            selected={isSelected}
            onClick={(e) => { e.preventDefault(); e.stopPropagation(); setIsSelected((p) => !p); }}
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
            <ChipBase><IdAtom>#{wpid}</IdAtom></ChipBase>
          </InlineChip>
        );
      }

      return <InlineChip ref={setRef} />;
    },

    toExternalHTML: ({ inlineContent }) => {
      const { wpid, instanceId, size } = inlineContent.props;
      if (!wpid || wpid.startsWith("pending:")) return <></>;
      return (
        <a
          href={`./wp/${wpid}`}
          target="_blank"
          rel="noopener noreferrer"
          data-inline-wp={wpid}
          data-inline-wp-instance={instanceId}
          data-inline-wp-size={size ?? "s"}
        >
          #{wpid}
        </a>
      );
    },
  }
);
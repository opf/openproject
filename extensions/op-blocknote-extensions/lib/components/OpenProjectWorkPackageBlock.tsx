import { BlockNoteEditor, insertOrUpdateBlock, type BlockConfig, type InlineContentSchema, type StyleSchema } from "@blocknote/core";
import { createReactBlockSpec } from "@blocknote/react";
import React, { useEffect, useRef, useState } from "react";
import { useWorkPackage } from "../hooks/useWorkPackage";
import { useWorkPackageSearch } from "../hooks/useWorkPackageSearch";
import type { WorkPackage } from "../openProjectTypes";
import { linkToWorkPackage } from "../services/openProjectApi";

const UI_BLUE = "#000091"; // Default color for task status icons
const UI_BEIGE = "#FBF5F2";

interface BlockProps {
  props: {
    wpid: string;
    subject: string;
    status: string;
    assignee: string;
    type: string;
    href: string;
  };
}

const OpenProjectWorkPackageBlockComponent = ({
  block,
  editor,
}: {
  block: BlockProps;
  editor: any;
}) => {
  const inputRef = useRef<HTMLInputElement>(null);
  const dropdownRef = useRef<HTMLDivElement>(null);

  // Search mode state (API + debounce only)
  const {
    searchQuery,
    setSearchQuery,
    searchResults,
    // loading: searchLoading,
    // error: searchError,
  } = useWorkPackageSearch();

  const [selectedWorkPackage, setSelectedWorkPackage] = useState<WorkPackage | null>(null);
  const [isDropdownOpen, setIsDropdownOpen] = useState(false);
  const [focusedResultIndex, setFocusedResultIndex] = useState(-1);

  // Load saved work package if it exists
  const workPackageResult = useWorkPackage(block.props.wpid);
  if (!workPackageResult.error && workPackageResult.workPackage) {
    setSelectedWorkPackage(workPackageResult.workPackage);
  } else {
    // Autofocus search
    setTimeout(() => inputRef?.current?.focus(), 50);
  }

  // Handle click outside to close dropdown
  useEffect(() => {
    const handleClickOutside = (event: MouseEvent) => {
      if (
        dropdownRef.current &&
        !dropdownRef.current.contains(event.target as Node) &&
        inputRef.current &&
        !inputRef.current.contains(event.target as Node)
      ) {
        setIsDropdownOpen(false);
      }
    };

    document.addEventListener("mousedown", handleClickOutside);
    return () => {
      document.removeEventListener("mousedown", handleClickOutside);
    };
  }, []);

  const handleSelectWorkPackage = (workPackage: WorkPackage) => {
    setSelectedWorkPackage(workPackage);
    setSearchQuery("");
    setIsDropdownOpen(false);

    // Update block props to persist the selection
    editor.updateBlock(block, {
      props: {
        ...block.props,
        wpid: workPackage.id,
        subject: workPackage.subject,
        status: workPackage._links?.status?.title || "",
        assignee: workPackage._links?.assignee?.title || "",
        type: workPackage._links?.type?.title || "",
        href: workPackage._links?.self?.href || "",
      },
    });
  };

  // Handle keyboard navigation
  const handleKeyDown = (e: React.KeyboardEvent) => {
    if (!isDropdownOpen) {
      return;
    }

    switch (e.key) {
      case "ArrowDown":
        e.preventDefault();
        setFocusedResultIndex((prev) => (prev < searchResults.length - 1 ? prev + 1 : prev));
        break;
      case "ArrowUp":
        e.preventDefault();
        setFocusedResultIndex((prev) => (prev > 0 ? prev - 1 : 0));
        break;
      case "Enter":
        e.preventDefault();
        if (focusedResultIndex >= 0 && focusedResultIndex < searchResults.length) {
          handleSelectWorkPackage(searchResults[focusedResultIndex]);
        }
        break;
      case "Escape":
        e.preventDefault();
        setIsDropdownOpen(false);
        break;
      default:
        break;
    }
  };

  return (
    <div
      style={{
        padding: "12px 10px",
        border: "none",
        borderRadius: "5px",
        backgroundColor: UI_BEIGE,
        width: "450px",
      }}
    >
      <div>
        {!block.props.wpid && (
          <div style={{ position: "relative" }}>
            <div
              style={{
                display: "flex",
              }}
            >
              <input
                ref={inputRef}
                type="text"
                placeholder={"Search for work package ID or subject"}
                value={searchQuery}
                onChange={(e) => {
                  setSearchQuery(e.target.value);
                  if (e.target.value) {
                    setIsDropdownOpen(true);
                  }
                }}
                onFocus={() => {
                  if (searchResults.length > 0) {
                    setIsDropdownOpen(true);
                  }
                }}
                onKeyDown={handleKeyDown}
                style={{
                  width: "100%",
                  padding: "8px 12px",
                  borderRadius: "4px",
                  border: "1px solid #ccc",
                  fontSize: "14px",
                }}
              />
              {/* <button onClick={() => setMode('create')}>
                  {t('New Work Package')}
                </button> */}
            </div>

            {/* Autocomplete dropdown */}
            {isDropdownOpen && searchResults.length > 0 && (
              <div
                ref={dropdownRef}
                role="listbox"
                aria-label={"Work package search results"}
                style={{
                  position: "absolute",
                  top: "100%",
                  left: 0,
                  right: 0,
                  zIndex: 10,
                  backgroundColor: "white",
                  border: "1px solid #ccc",
                  borderRadius: "0 0 4px 4px",
                  boxShadow: "0 2px 4px rgba(0,0,0,0.1)",
                  maxHeight: "200px",
                  overflowY: "auto",
                  marginTop: "2px",
                }}
              >
                {searchResults.slice(0, 5).map((wp, index) => (
                  <div
                    key={wp.id}
                    role="option"
                    aria-selected={focusedResultIndex === index}
                    tabIndex={0}
                    onClick={() => handleSelectWorkPackage(wp)}
                    onKeyDown={(e) => {
                      if (e.key === "Enter" || e.key === " ") {
                        e.preventDefault();
                        handleSelectWorkPackage(wp);
                      }
                    }}
                    onMouseEnter={() => setFocusedResultIndex(index)}
                    style={{
                      padding: "8px 12px",
                      cursor: "pointer",
                      backgroundColor: focusedResultIndex === index ? "#f0f0f0" : "transparent",
                      borderBottom: index < searchResults.length - 1 ? "1px solid #eee" : "none",
                    }}
                  >
                    <div style={{ fontWeight: "bold" }}>
                      #{wp.id} - {wp.subject}
                    </div>
                    <div style={{ fontSize: "12px", color: "#666" }}>
                      {wp._links?.type?.title} {wp._links?.status?.title}
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>
        )}
        {block.props.wpid && !selectedWorkPackage && (
          <div>
            #{block.props.wpid} {block.props.subject}
          </div>
        )}
        {/* Display selected work package details */}
        {selectedWorkPackage && (
          <div>
            <div
              style={{
                display: "flex",
                gap: "8px",
              }}
            >
              <div
                style={{
                  gap: "8px",
                  color: selectedWorkPackage._embedded?.type?.color || UI_BLUE,
                  fontWeight: "bold",
                  textTransform: "uppercase",
                }}
              >
                {selectedWorkPackage._links?.type?.title}
              </div>
              <div
                style={{
                  color: "#666",
                }}
              >
                #{selectedWorkPackage.id}
              </div>
              <div
                style={{
                  fontSize: "0.8rem",
                  borderRadius: "12px",
                  padding: "2px 8px",
                  border: "1px solid #ccc",
                  backgroundColor: selectedWorkPackage._embedded?.status?.color || UI_BLUE,
                }}
              >
                {selectedWorkPackage._links?.status?.title}
              </div>
            </div>

            <div>
              <a href={linkToWorkPackage(block.props.wpid)} style={{
                  marginRight: 6,
                  textDecoration: "none",
                  color: UI_BLUE,
                  cursor: "pointer",
              }} >
                {selectedWorkPackage.subject}
              </a>
            </div>
          </div>
        )}
      </div>
    </div>
  );
};

export default OpenProjectWorkPackageBlockComponent;

export const openProjectWorkPackageBlockSpec = createReactBlockSpec(
  {
    type: "openProjectWorkPackage",
    propSchema: {
      wpid: { default: "", type: "string" },
      subject: { default: "", type: "string" },
      status: { default: "", type: "string" },
      assignee: { default: "", type: "string" },
      type: { default: "", type: "string" },
      href: { default: "", type: "string" },
    },
    content: "inline",
  },
  {
    render: (props) => {
      return <OpenProjectWorkPackageBlockComponent block={props.block} editor={props.editor} />;
    },
  },
);

export const openProjectWorkPackageSlashMenu = (editor: BlockNoteEditor<Record<string, BlockConfig>, InlineContentSchema, StyleSchema>) => ({
  title: "Open Project Work Package",
  onItemClick: () =>
    insertOrUpdateBlock(editor, {
      type: "openProjectWorkPackage",
    }),
  aliases: ["openproject", "workpackage", "op", "wp"],
  group: "OpenProject",
  icon: <span>📦</span>,
  subtext: "Search and link an existing Work Package",
})

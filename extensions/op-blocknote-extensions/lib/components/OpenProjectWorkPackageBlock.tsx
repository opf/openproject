import type { DefaultBlockSchema } from "@blocknote/core";
import { BlockNoteEditor, createBlockConfig, createBlockSpec, insertOrUpdateBlock } from "@blocknote/core";
import { createReactBlockSpec } from "@blocknote/react";
import React, { useEffect, useRef, useState } from "react";
import { useWorkPackage } from "../hooks/useWorkPackage";
import { useWorkPackageSearch } from "../hooks/useWorkPackageSearch";
import type { WorkPackage } from "../openProjectTypes";
import { linkToWorkPackage } from "../services/openProjectApi";
import { defaultVariables, defaultColorStyles, useColors, typeColor, statusColor, statusBorderColor, statusTextColor, statusBackgroundColor, typeTextColor } from "../services/colors";
import { LinkIcon, SearchIcon } from "@primer/octicons-react";

import styled from "styled-components";

const SPACER_S = "4px";
const SPACER_M = "8px";
const SPACER_L = "12px";
const SPACER_XL = "16px";

const Block = styled.div`
    --highlight-wp-background: var(--bn-colors-highlights-gray-background);
    [data-color-scheme="dark"] & {
        --highlight-wp-background: var(--bn-colors-disabled-text);
    }
`;

const Search = styled.div`
  position: relative;
  padding: ${SPACER_M} ${SPACER_XL};
  box-shadow: var(--bn-shadow-medium);
  border-radius: var(--bn-border-radius-large);
  width: 100%;
  @media (min-width: 1120px) {
    width: 500px;
  }
`;

const SearchLabel = styled.label`
  font-weight: normal !important;
`;

const SearchInputWrapper = styled.div`
  position: relative;
  margin-top: ${SPACER_M};
`;

const SearchIconWrapper = styled.div`
  position: absolute;
  top: 50%;
  transform: translateY(-50%);
  padding-left: ${SPACER_M};
`;
const SearchInput = styled.input`
  width: 100%;
  padding: ${SPACER_M} ${SPACER_L};
  padding-left: 30px !important; // room for the search icon
  border: 1px solid #ccc;
  border-radius: var(--bn-border-radius-small);
  font-size: 14px;
`;

const Dropdown = styled.div`
  background-color: var(--bn-colors-menu-background);
  overflow-y: auto;
  padding-top: ${SPACER_M};
  margin: 0 -${SPACER_M};
`;

const DropdownOption = styled.div<{ selected: boolean }>`
  background-color: ${({ selected }) => selected ? 'var(--highlight-wp-background)' : 'var(--bn-colors-menu-background)'};
  border: none;
  border-radius: var(--bn-border-radius-small);
  margin: ${SPACER_S} 0;
  padding: 0 ${SPACER_M};
  cursor: pointer;
`;

const WorkPackage = styled.div<{ in_dropdown?: boolean }>`
  ${defaultVariables}
  padding: ${SPACER_M} ${SPACER_L};
  background-color: var(--highlight-wp-background);
  border-radius: var(--bn-border-radius-small);
  ${({ in_dropdown }) => in_dropdown && `
    padding: ${SPACER_S} 0;
    background-color: transparent; 
  `}
`;

const WorkPackageDetails = styled.div`
  display: flex;
  flex-wrap: wrap;
  gap: 0 10px;
  width: 100%;
`;

const WorkPackageType = styled.div<{ color: string }>`
  ${({ color }) => defaultColorStyles(color)}
  font-weight: 500;
  text-transform: uppercase;
  color: ${() => typeTextColor} !important;
`;

const WorkPackageId = styled.div`
  color: var(--bn-colors-highlights-gray-text);
`;

const WorkPackageStatus = styled.div<{ base_color: string }>`
  ${({ base_color }) => defaultColorStyles(base_color)}
  font-size: 0.8rem;
  border-radius: 100px;
  border: 1px solid ${() => statusBorderColor()};
  padding: 0 7px;
  align-content: center;
  color: ${() => statusTextColor()} !important;
  background-color: ${() => statusBackgroundColor()};
`;

const WorkPackageTitle = styled.div`
  flex-basis: max-content;
  color: var(--bn-colors-editor-text);
  font-weight: 500;
    
  a {
    cursor: pointer;
    text-decoration: none;
    color: var(--bn-colors-highlights-blue-text);

    &:hover {
        text-decoration: underline;
    }
  }
`;

const UnavailableMessage = styled.div`
  color: var(--bn-colors-editor-text) !important;
`

const UnavailableMessageHeader = styled.div`
  font-weight: 600;
  color: var(--bn-colors-editor-text) !important;
`

interface BlockProps {
  id: string,
  props: {
    wpid: string;
  };
}

const WorkPackageElement = ({ workPackage, inDropdown, linkTitle }: {workPackage: WorkPackage, inDropdown?: boolean, linkTitle?: boolean}) => {
  let title = undefined
  if(linkTitle ?? false) {
    title = <a
      href={linkToWorkPackage(workPackage.id)}
      onClick={(event) => {
        event.stopPropagation();
        window.open(linkToWorkPackage(workPackage.id), '_blank', 'noopener,noreferrer');
      }}
    >
      {workPackage.subject}
    </a>
  } else {
    title = workPackage.subject
  }

  return (
    <WorkPackage in_dropdown={inDropdown ?? false}>
      <WorkPackageDetails>
        <WorkPackageType color={typeColor(workPackage)}>{workPackage._links?.type?.title}</WorkPackageType>
        <WorkPackageId>#{workPackage.id}</WorkPackageId>
        <WorkPackageStatus base_color={statusColor(workPackage)}>
          {workPackage._links?.status?.title}
        </WorkPackageStatus>
      </WorkPackageDetails>
      <WorkPackageTitle>{title}</WorkPackageTitle>
    </WorkPackage>
  )
}
const UnavailableWorkPackageElement = ({ header, message }: {header: string, message: string}) => {
  return (
    <WorkPackage>
      <UnavailableMessage>
        <UnavailableMessageHeader>
          { header }
        </UnavailableMessageHeader>
        { message }
      </UnavailableMessage>
    </WorkPackage>
  )
}

const OpenProjectWorkPackageBlockComponent = ({
  block,
  editor,
}: {
  block: BlockProps;
  editor: BlockNoteEditor<DefaultBlockSchema & { openProjectWorkPackage: ReturnType<typeof openprojectWorkPackageBlockConfig> }>;
}) => {
  const inputRef = useRef<HTMLInputElement>(null);
  const dropdownRef = useRef<HTMLDivElement>(null);

  // Fetch and cache colors.
  // The hook handles triggering re-renders when data arrives.
  useColors();

  // Search mode state (API + debounce only)
  const {
    searchQuery,
    setSearchQuery,
    searchResults,
  } = useWorkPackageSearch();

  const [selectedWorkPackage, setSelectedWorkPackage] = useState<WorkPackage | null>(null);
  const [isDropdownOpen, setIsDropdownOpen] = useState(false);
  const [focusedResultIndex, setFocusedResultIndex] = useState(-1);

  // Load saved work package if it exists
  const workPackageResult = useWorkPackage(block.props.wpid);

  // Set selected work package when loaded
  useEffect(() => {
    if (!workPackageResult.error && workPackageResult.workPackage) {
      setSelectedWorkPackage(workPackageResult.workPackage);
    }
  }, [workPackageResult.error, workPackageResult.workPackage]);

  // Autofocus search if no work package
  useEffect(() => {
    if (workPackageResult.error || !workPackageResult.workPackage) {
      setTimeout(() => inputRef?.current?.focus(), 50);
    }
  }, [workPackageResult.error, workPackageResult.workPackage]);

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
    <Block>
      <div>
        {/* Show search dialog if no work package is selected yet */}
        {!block.props.wpid && (
          <Search>
            <SearchLabel>
              Link existing work package
              <SearchInputWrapper>
                <SearchIconWrapper>
                  <SearchIcon size={18} />
                </SearchIconWrapper>
                <SearchInput
                  ref={inputRef}
                  type="custom"
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
                />
              </SearchInputWrapper>
            </SearchLabel>

            {/* Autocomplete dropdown */}
            {isDropdownOpen && searchResults.length > 0 && (
              <Dropdown
                ref={dropdownRef}
                role="listbox"
                aria-label={"Work package search results"}
              >
                {searchResults.slice(0, 5).map((wp, index) => (
                  <DropdownOption
                    key={wp.id}
                    role="option"
                    aria-selected={focusedResultIndex === index}
                    tabIndex={0}
                    selected={focusedResultIndex === index}
                    onClick={() => handleSelectWorkPackage(wp)}
                    onKeyDown={(e) => {
                      if (e.key === "Enter" || e.key === " ") {
                        e.preventDefault();
                        handleSelectWorkPackage(wp);
                      }
                    }}
                    onMouseEnter={() => setFocusedResultIndex(index)}
                  >
                    <WorkPackageElement workPackage={wp} inDropdown={true} />
                  </DropdownOption>
                ))}
              </Dropdown>
            )}
          </Search>
        )}

        {/* Show work package data (if available) */}
        {block.props.wpid && !selectedWorkPackage && workPackageResult.loading && (
          <UnavailableWorkPackageElement header="Loading" message="Please wait" />
        )}
        {block.props.wpid && !selectedWorkPackage && workPackageResult.unauthorized &&  (
          <UnavailableWorkPackageElement header="Linked work package unavailable" message="You do not have permission to see this" />
        )}
        {block.props.wpid && !selectedWorkPackage && workPackageResult.error && (
          <UnavailableWorkPackageElement header="Error" message="Could not load work package" />
        )}
        {selectedWorkPackage && (
          <WorkPackageElement workPackage={selectedWorkPackage} linkTitle={true} />
        )}
      </div>
    </Block>
  );
};

export const openprojectWorkPackageBlockConfig = createBlockConfig(
  () => ({
    type: "openProjectWorkPackage",
    propSchema: {
      wpid: { default: "" },
    },
    content: "inline",
  }) as const
);

export const openProjectWorkPackageBlockSpec = createReactBlockSpec(
  openprojectWorkPackageBlockConfig,
  { render: (props) => <OpenProjectWorkPackageBlockComponent block={props.block} editor={props.editor as any} /> }
);

export const openProjectWorkPackageStaticBlockSpec = createBlockSpec(
  openprojectWorkPackageBlockConfig,
  {
    render: (block) => {
      const wpid = block.props.wpid;
      const href = linkToWorkPackage(wpid);

      const anchor = document.createElement("a");
      anchor.href = href;
      anchor.target = "_blank";
      anchor.rel = "noopener noreferrer";
      anchor.textContent = `#${wpid}`;

      return {
        dom: anchor,
        contentDOM: anchor,
      };
    }
  }
);

export const openProjectWorkPackageSlashMenu = (editor: any) => ({
  title: "Link to existing work package",
  onItemClick: () => insertOrUpdateBlock(editor, { type: "openProjectWorkPackage" }),
  aliases: ["openproject", "op", "workpackage", "work package", "wp", "link",
    "openproject work package link", "openproject workpackage link", "openproject wp link",
    "op work package link", "op workpackage link", "op wp link",
    "openproject link work package", "openproject link workpackage", "openproject link wp",
    "op link work package", "op link workpackage", "op link wp",
    "work package openproject link", "work package op link",
    "workpackage openproject link", "workpackage op link",
    "wp openproject link", "wp op link",
    "work package link openproject", "work package link op",
    "workpackage link openproject", "workpackage link op",
    "wp link openproject", "wp link op",
    "link work package openproject", "link work package op",
    "link workpackage openproject", "link workpackage op",
    "link wp openproject", "link wp op",
    "link openproject work package", "link openproject workpackage", "link openproject wp",
    "link op work package", "link op workpackage", "link op wp",
  ],
  group: "OpenProject",
  icon: <LinkIcon size={18} />,
  subtext: "Add a dynamic link to a single work package",
})

import { useEffect, useRef } from 'react';
import type { ReactNode } from 'react';
import { useTranslation } from 'react-i18next';
import {
  ChevronDownIcon,
  ChevronRightIcon,
  StarFillIcon,
  XCircleIcon,
} from '@primer/octicons-react';
import { useAnchoredPopover } from '../WorkPackage/anchoredPopover';
import type { AllowedValue, ListedValue } from './formSchema';
import {
  ACTION_ICON_SIZE,
  FavoredMark,
  LevelLine,
  RowAction,
  SuggestionEmpty,
  SuggestionHeader,
  SuggestionItem,
  SuggestionLabel,
  SuggestionList,
  SuggestionTree,
  Twisty,
} from './atoms';

const MAX_LIST_HEIGHT = 320;
const LIST_OFFSET = 2;

interface SuggestionsProps {
  id:string;
  label:string;
  anchorEl:HTMLElement | null;
  options:ListedValue[];
  focusedIndex:number;
  selectedHref:string;
  hierarchical?:boolean;
  header?:ReactNode;
  optionId:(index:number) => string;
  onFocusIndex:(index:number) => void;
  onPick:(option:AllowedValue) => void;
  onDeselect:() => void;
  onToggleExpanded:(href:string) => void;
  children:ReactNode;
}

export const Suggestions = ({
  id,
  label,
  anchorEl,
  options,
  focusedIndex,
  selectedHref,
  hierarchical,
  header,
  optionId,
  onFocusIndex,
  onPick,
  onDeselect,
  onToggleExpanded,
  children,
}:SuggestionsProps) => {
  const { t } = useTranslation();
  const listRef = useRef<HTMLDivElement>(null);

  useAnchoredPopover({
    anchorEl,
    popoverRef: listRef,
    placement: 'below',
    offset: LIST_OFFSET,
    matchAnchorWidth: true,
    maxHeight: MAX_LIST_HEIGHT,
    resizeKey: options.length,
  });

  useEffect(() => {
    listRef.current
      ?.querySelectorAll('[role="option"], [role="treeitem"]')[focusedIndex]
      ?.scrollIntoView({ block: 'nearest' });
  }, [focusedIndex, options]);

  return (
    <SuggestionList
      ref={listRef}
      data-testid={`${id}-popover`}
      onMouseDown={(event) => {
        if (!(event.target instanceof HTMLInputElement)) event.preventDefault();
      }}
    >
      {header && <SuggestionHeader>{header}</SuggestionHeader>}

      <SuggestionTree role={hierarchical ? 'tree' : 'listbox'} id={id} aria-label={label}>
        {options.map((option, index) => (
          <SuggestionItem
            key={option.href}
            id={optionId(index)}
            role={hierarchical ? 'treeitem' : 'option'}
            aria-selected={option.href === selectedHref}
            {...(hierarchical ? {
              'aria-expanded': option.hasChildren ? option.expanded : undefined,
              'aria-level': option.depth + 1,
              'aria-posinset': option.position,
              'aria-setsize': option.levelSize,
            } : {})}
            $focused={index === focusedIndex}
            $selected={option.href === selectedHref}
            onMouseEnter={() => onFocusIndex(index)}
            onMouseDown={(event) => {
              event.preventDefault();
              onPick(option);
            }}
          >
            {Array.from({ length: option.depth }, (_, level) => (
              <LevelLine key={level} data-testid={`${id}-level-line`} />
            ))}

            <Twisty
              $foldable={option.hasChildren}
              $indent={option.depth}
              data-testid={`${id}-twisty-${index}`}
              onMouseDown={(event) => {
                if (!option.hasChildren) return;
                // Unfolding a parent is not picking it.
                event.preventDefault();
                event.stopPropagation();
                onToggleExpanded(option.href);
              }}
            >
              {option.hasChildren && (
                option.expanded ? <ChevronDownIcon size={12} /> : <ChevronRightIcon size={12} />
              )}
            </Twisty>

            <SuggestionLabel>{option.label}</SuggestionLabel>

            {option.favored && (
              <FavoredMark>
                <StarFillIcon size={12} />
              </FavoredMark>
            )}

            {option.href === selectedHref && (
              <RowAction
                aria-label={t('createWorkPackage.deselect')}
                data-testid={`${id}-deselect`}
                onMouseDown={(event) => {
                  event.preventDefault();
                  event.stopPropagation();
                  onDeselect();
                }}
              >
                <XCircleIcon size={ACTION_ICON_SIZE} />
              </RowAction>
            )}
          </SuggestionItem>
        ))}
      </SuggestionTree>

      {options.length === 0 && <SuggestionEmpty>{children}</SuggestionEmpty>}
    </SuggestionList>
  );
};

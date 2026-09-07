import { useCallback, useEffect, useLayoutEffect, useRef, useState } from 'react';
import type { ReactNode } from 'react';
import { useTranslation } from 'react-i18next';
import {
  ChevronDownIcon,
  ChevronRightIcon,
  StarFillIcon,
  XCircleIcon,
} from '@primer/octicons-react';
import { wantsMotion } from '../../utils/motion';
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
const OPEN_DURATION = 150;
const CLOSE_DURATION = 110;
const RESIZE_DURATION = 150;

// Clipped, not transformed: a transform would move the box the list is positioned by.
const rolledUp = (height:number, downwards:boolean):string =>
  (downwards ? `inset(0px 0px ${height}px 0px)` : `inset(${height}px 0px 0px 0px)`);
const rolledDown = 'inset(0px 0px 0px 0px)';

const opensDownwards = (list:HTMLElement, anchorEl:HTMLElement | null):boolean =>
  !anchorEl || list.getBoundingClientRect().top >= anchorEl.getBoundingClientRect().top;

export function usePickerMotion(isOpen:boolean):{
  mounted:boolean;
  open:boolean;
  onClosed:() => void;
} {
  const [closed, setClosed] = useState(true);
  if (isOpen && closed) setClosed(false);

  const onClosed = useCallback(() => setClosed(true), []);

  return { mounted: isOpen || !closed, open: isOpen, onClosed };
}

interface SuggestionsProps {
  id:string;
  label:string;
  anchorEl:HTMLElement | null;
  options:ListedValue[];
  focusedIndex:number;
  selectedHref?:string;
  hierarchical?:boolean;
  header?:ReactNode;
  optionId:(index:number) => string;
  onFocusIndex:(index:number) => void;
  onPick:(option:AllowedValue) => void;
  onDeselect?:() => void;
  onToggleExpanded:(href:string) => void;
  leadingOf?:(option:ListedValue) => ReactNode;
  open:boolean;
  onClosed:() => void;
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
  leadingOf,
  open,
  onClosed,
  children,
}:SuggestionsProps) => {
  const { t } = useTranslation();
  const listRef = useRef<HTMLDivElement>(null);
  const heldAt = useRef<number | null>(null);
  const crossedTo = useRef<number | null>(null);
  const rolledOpen = useRef(false);

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

  const shape = options.map((option) => option.href).join('\u0000');

  useLayoutEffect(() => {
    const list = listRef.current;
    if (!list) return;

    const shown = heldAt.current ?? list.getBoundingClientRect().height;
    heldAt.current = null;
    delete list.dataset.growing;

    if (!wantsMotion()) {
      if (open) rolledOpen.current = true;
      else onClosed();
      crossedTo.current = list.getBoundingClientRect().height;
      return;
    }

    let animation:Animation;

    if (!open) {
      const away = rolledUp(shown, opensDownwards(list, anchorEl));
      animation = list.animate(
        [
          { clipPath: rolledDown, height: `${shown}px` },
          { clipPath: away, height: `${shown}px` },
        ],
        { duration: CLOSE_DURATION, easing: 'ease-in', fill: 'forwards' }
      );
      animation.addEventListener('finish', onClosed);
    } else if (!rolledOpen.current) {
      rolledOpen.current = true;
      crossedTo.current = list.offsetHeight;
      const shut = rolledUp(list.offsetHeight, opensDownwards(list, anchorEl));
      animation = list.animate(
        [{ clipPath: shut }, { clipPath: rolledDown }],
        { duration: OPEN_DURATION, easing: 'ease-out' }
      );
    } else {
      const to = list.getBoundingClientRect().height;
      const from = crossedTo.current;
      crossedTo.current = to;
      if (from === null || Math.abs(to - from) < 1) return;

      if (list.scrollHeight - list.clientHeight < 1) list.dataset.growing = '';
      animation = list.animate(
        [{ height: `${from}px` }, { height: `${to}px` }],
        { duration: RESIZE_DURATION, easing: 'ease-out' }
      );
      animation.addEventListener('finish', () => { delete list.dataset.growing; });
    }

    return () => {
      heldAt.current = list.getBoundingClientRect().height;
      animation.cancel();
      delete list.dataset.growing;
    };
  }, [open, shape, onClosed, anchorEl]);

  return (
    <SuggestionList
      ref={listRef}
      data-testid={`${id}-popover`}
      aria-hidden={!open}
      $closing={!open}
      onMouseDown={(event) => event.preventDefault()}
    >
      {header && <SuggestionHeader data-testid={`${id}-header`}>{header}</SuggestionHeader>}

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
            onMouseMove={() => { if (index !== focusedIndex) onFocusIndex(index); }}
            onMouseDown={(event) => {
              event.preventDefault();
              onPick(option);
            }}
          >
            {Array.from({ length: option.depth }, (_, level) => (
              <LevelLine key={level} data-testid={`${id}-level-line`} />
            ))}

            {hierarchical && (
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
            )}

            {leadingOf?.(option)}

            <SuggestionLabel>{option.label}</SuggestionLabel>

            {option.favored && (
              <FavoredMark>
                <StarFillIcon size={12} />
              </FavoredMark>
            )}

            {onDeselect && option.href === selectedHref && (
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

//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) the OpenProject GmbH
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2013 Jean-Philippe Lang
// Copyright (C) 2010-2013 the ChiliProject Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { BatchSelection, type SelectionAnchor, type SelectionKey } from 'core-common/batch-selection';
import { announce } from '@primer/live-region-element';
import { resolveItemId, resolveItemType } from './list-dom';
import {
  applySelectionPresentation,
  listBoundaryItem,
  liveOrderableKeys,
  liveOrderableListItems,
  neighbourItem,
  orderedItemElements,
  orderedSelectedItems,
  resolveCandidate,
  resolveRangeItems,
  type SelectionCandidate,
} from './selection';
import { closestInteractiveElement } from 'core-common/interactive-element-helper';
import { isApplePlatform } from 'core-stimulus/helpers/platform';

/**
 * What the orchestrator needs from whatever hosts it.
 */
export interface SelectionHost {
  readonly rootElement:HTMLElement;
  readonly busy:boolean;
  readonly announcementScope:string;
  readonly descriptionId:string;
  // The consumer decides which element inside a row holds the tab stop.
  focusItem(itemElement:HTMLElement):void;
  // Must be the container moves use, so ranges and moves agree on what a
  // list's rows are.
  ownerRowsContainer(itemElement:HTMLElement):HTMLElement|null;
}

/**
 * Batch selection: gestures in, model and presentation out.
 */
// Read the way browsers bind their own select-all: by the key's meaning on
// Latin layouts (AZERTY's Ctrl+A sits on physical KeyQ), by the physical key
// where the layout prints another letter (Cyrillic ф, Greek α on KeyA). A
// dead key, composition or an AltGr chord is input, not a shortcut.
function isSelectAllKey(event:KeyboardEvent):boolean {
  if (event.isComposing || event.altKey || event.getModifierState('AltGraph')) {
    return false;
  }

  return event.key === 'a' || event.key === 'A'
    || (event.code === 'KeyA' && /^\p{L}$/u.test(event.key) && !/^\p{Script=Latin}$/u.test(event.key));
}

// Every root listens for Escape at the document, so the first to clear
// would otherwise look to the next like an overlay that consumed the key.
const escapesClearedBySelection = new WeakSet<Event>();

export class SelectionOrchestrator {
  private readonly selection = new BatchSelection();

  // Last painted membership, not last announced: a silent navigation render
  // in between would leave a stale baseline and make the next no-op speak.
  private lastRenderedKeys:ReadonlySet<SelectionKey> = new Set();

  constructor(private readonly host:SelectionHost) {}

  // Live ordered membership, for AGILE-278's batch move.
  selectedIds():string[] {
    return orderedSelectedItems(this.host.rootElement, this.selection.keys).map((item) => item.id);
  }

  // A menu move relocates exactly one card, so it collapses like a drag.
  collapseForMove(itemElement:HTMLElement):void {
    this.collapseForDrag(itemElement);
  }

  collapseForDrag(itemElement:HTMLElement):void {
    // Nothing selected is nothing to collapse: a drag must not manufacture
    // a one-card batch.
    if (this.selection.size === 0) {
      return;
    }

    const candidate = resolveCandidate(this.host.rootElement, itemElement);
    if (!candidate?.orderable) {
      return;
    }

    this.selection.replace({ type: candidate.type, id: candidate.id }, candidate.listKey);
    this.renderSelection('selection');
  }

  // The platform's one multi-select modifier: ⌘ on Apple platforms, Ctrl
  // elsewhere. Meta is not an alternate modifier on Windows or Linux, and
  // Ctrl on Apple is the secondary click, never multi-select.
  private multiSelectModifier(event:MouseEvent|KeyboardEvent):boolean {
    return isApplePlatform() ? event.metaKey : event.ctrlKey;
  }

  readonly handleClick = (event:MouseEvent):void => {
    // Ctrl-click is the secondary click on Apple platforms, where it opens
    // the contextual menu and Cmd is the multi-select key instead.
    if (event.ctrlKey && !event.metaKey && !event.shiftKey && isApplePlatform()) {
      return;
    }

    const multiSelect = this.multiSelectModifier(event);
    const modified = event.shiftKey || multiSelect;
    const candidate = this.candidateForGesture(event.target);
    if (!candidate) {
      return;
    }

    if (!modified) {
      // Consumed before the busy check: falling through mid-move would open
      // the details pane on a card the batch was not allowed to follow.
      if (this.host.busy) {
        event.preventDefault();
        event.stopPropagation();
        return;
      }

      // A fixed card cannot join the batch, but must still clear the one
      // behind it.
      if (candidate.orderable) {
        this.selection.replace({ type: candidate.type, id: candidate.id }, candidate.listKey);
        this.renderSelection('navigation');
      } else {
        this.selection.clear();
        this.renderSelection('navigation');
      }
      return;
    }

    // Consumed regardless of `busy`: a modified gesture reaching the card's
    // own click handler would open the details pane on a selection toggle.
    event.preventDefault();
    event.stopPropagation();

    if (this.host.busy) {
      return;
    }

    if (!candidate.orderable) {
      this.announceSelection('not_selectable');
      return;
    }

    if (event.shiftKey) {
      this.extendSelectionTo(candidate);
    } else {
      this.toggleWithinCohort(candidate);
      this.renderSelection('selection');
    }
  };

  // A link inside a card is a link first. The walk stops at the focus host
  // when the gesture landed inside it — the host may be focusable itself,
  // Backlogs cards carry tabindex — and at the item otherwise, which keeps
  // it bounded to the row for a host nested deeper than the item.
  private candidateForGesture(target:EventTarget|null):SelectionCandidate|null {
    const candidate = resolveCandidate(this.host.rootElement, target);
    if (!candidate) {
      return null;
    }

    if (!(target instanceof Element)) {
      return candidate;
    }

    const boundary = candidate.focusHost.contains(target) ? candidate.focusHost : candidate.itemElement;
    const interactive = closestInteractiveElement(target, boundary);

    return interactive ? null : candidate;
  }

  readonly handleKeydown = (event:KeyboardEvent):void => {
    const candidate = this.candidateForGesture(event.target);
    if (!candidate) {
      return;
    }

    switch (event.key) {
      case ' ':
        this.handleSpace(event, candidate);
        break;
      case 'ArrowDown':
      case 'ArrowUp':
        this.handleArrow(event, candidate, event.key === 'ArrowDown' ? 1 : -1);
        break;
      case 'Home':
      case 'End':
        this.handleBoundary(event, candidate, event.key === 'Home' ? 'first' : 'last');
        break;
      default:
        // Enter belongs to the card's own activation handler; Escape is
        // handled at the document.
        if (isSelectAllKey(event)) {
          this.handleSelectAll(event, candidate);
        }
        break;
    }
  };

  private handleSpace(event:KeyboardEvent, candidate:SelectionCandidate):void {
    event.preventDefault();

    // A held Space would otherwise toggle the card over and over.
    if (event.repeat) {
      return;
    }

    if (this.host.busy) {
      return;
    }

    if (!candidate.orderable) {
      this.announceSelection('not_selectable');
      return;
    }

    if (event.shiftKey) {
      this.extendSelectionTo(candidate);
    } else {
      this.toggleWithinCohort(candidate);
      this.renderSelection('selection');
    }
  }

  // Consumed even at a list boundary: an unconsumed arrow scrolls the page
  // while focus stays put.
  private handleArrow(event:KeyboardEvent, candidate:SelectionCandidate, offset:1|-1):void {
    event.preventDefault();

    const next = neighbourItem(this.host.rootElement, candidate.itemElement, offset);
    if (!next) {
      return;
    }

    this.focusAndMaybeExtend(event, next);
  }

  // Consumed like an arrow, including in both no-op cases below.
  private handleBoundary(event:KeyboardEvent, candidate:SelectionCandidate, edge:'first'|'last'):void {
    event.preventDefault();

    const target = listBoundaryItem(this.host.rootElement, candidate.itemElement, edge);
    if (!target) {
      return;
    }

    // With Shift held the range still resizes out to the boundary.
    if (target === candidate.itemElement && !event.shiftKey) {
      return;
    }

    this.focusAndMaybeExtend(event, target);
  }

  // Focus moves even mid-move: only the range mutation waits for the host.
  private focusAndMaybeExtend(event:KeyboardEvent, target:HTMLElement):void {
    this.focusItemElement(target);

    if (!event.shiftKey || this.host.busy) {
      return;
    }

    const candidate = resolveCandidate(this.host.rootElement, target);
    if (!candidate) {
      return;
    }

    if (candidate.orderable) {
      this.extendSelectionTo(candidate);
    } else {
      this.announceSelection('not_selectable');
    }
  }

  private focusItemElement(target:HTMLElement):void {
    this.host.focusItem(target);
  }

  // Confined to the focused card's list, like a range.
  private handleSelectAll(event:KeyboardEvent, candidate:SelectionCandidate):void {
    if (!this.multiSelectModifier(event)) {
      return;
    }

    const items = liveOrderableListItems(this.host.rootElement, candidate.itemElement)
      .filter((item) => item.type === candidate.type);
    // Only consumed once there is something to select: otherwise the
    // browser's own select-all still has to work.
    if (items.length === 0) {
      return;
    }

    event.preventDefault();

    if (this.host.busy) {
      return;
    }

    // A fixed focused card cannot anchor the batch, so the first orderable
    // card of the same list stands in.
    const anchor:SelectionAnchor = candidate.orderable
      ? { type: candidate.type, id: candidate.id, listKey: candidate.listKey }
      : { ...items[0], listKey: candidate.listKey };

    this.selection.selectAll(items, anchor);
    this.renderSelection('selection');
  }

  // At the document, in the bubble phase: focus routinely sits off the root
  // after a mouse selection, and an overlay's own Escape must run first.
  readonly handleEscape = (event:KeyboardEvent):void => {
    // A consumed Escape already answered the keystroke — unless it was
    // another root's selection that consumed it, in which case this root's
    // batch still has to go.
    if (event.key !== 'Escape' || (event.defaultPrevented && !escapesClearedBySelection.has(event))) {
      return;
    }

    if (!this.escapeConcernsSelection(event.target)) {
      return;
    }

    // BatchSelection#toggle re-bases the anchor even on a deselect, so an
    // emptied selection can still leave one behind for Escape to drop.
    const hadSelection = this.selection.size > 0;
    if (!hadSelection && this.selection.anchor === null) {
      return;
    }

    event.preventDefault();
    escapesClearedBySelection.add(event);
    this.selection.clear();
    this.renderSelection('selection');
  };

  // Escape drops the selection from wherever focus sits, except where the
  // key already means "dismiss this thing": an open overlay anywhere — focus
  // can still sit on its invoker for a frame after it opens — or a field
  // whose widget owns it (a picker, an inline editor, an autocompleter).
  private escapeConcernsSelection(target:EventTarget|null):boolean {
    if (document.querySelector('dialog[open], :popover-open')) {
      return false;
    }

    if (!(target instanceof Element)) {
      return true;
    }

    return target.closest(
      '[role="dialog"], [role="menu"], [role="listbox"], input, textarea, select, [contenteditable]',
    ) === null;
  }

  // A batch holds one item type: "all of these together" has no meaning
  // across two kinds of thing, and a collection move sends one list of ids
  // to one endpoint.
  private cohortMatches(candidate:SelectionCandidate):boolean {
    const { anchor } = this.selection;

    return anchor === null || anchor.type === candidate.type;
  }

  // Every adding gesture routes through here, which is what keeps a mixed
  // batch unreachable.
  private toggleWithinCohort(candidate:SelectionCandidate):void {
    if (!this.cohortMatches(candidate)) {
      this.renderRangeRestart(candidate);
      return;
    }

    this.selection.toggle({ type: candidate.type, id: candidate.id }, candidate.listKey);
    this.renderSelection('selection');
  }

  private extendSelectionTo(candidate:SelectionCandidate):void {
    const { anchor } = this.selection;

    if (anchor && !this.cohortMatches(candidate)) {
      this.renderRangeRestart(candidate);
      return;
    }

    if (!anchor) {
      this.renderRangeRestart(candidate);
      return;
    }

    const range = resolveRangeItems(
      this.host.rootElement,
      anchor,
      candidate,
      this.host.ownerRowsContainer(candidate.itemElement),
    );

    if (range.ok) {
      this.selection.range(range.items);
      this.renderSelection('selection');
      return;
    }

    if (range.reason === 'crossList') {
      this.renderRangeRestart(candidate);
      return;
    }

    // Expanding the list can surface a truncated block, but never makes a
    // locked card orderable, so the two speak different messages.
    this.announceSelection(range.reason === 'locked' ? 'range_blocked' : 'range_unavailable');
  }

  // Always speaks, unlike renderSelection's count rule: a Shift gesture that
  // failed to form a range has no other feedback, even when the resulting
  // count is unchanged.
  private renderRangeRestart(candidate:SelectionCandidate):void {
    this.selection.replace({ type: candidate.type, id: candidate.id }, candidate.listKey);
    this.syncSelectionPresentation();
    this.lastRenderedKeys = this.selection.keys;
    this.announceSelection('range_restarted');
  }

  // Announcement follows the gesture class, not the count: `navigation` (a
  // plain click) speaks only when it collapsed a batch, since the details
  // pane it opens is its own feedback for the card itself; `selection`
  // speaks on any membership change.
  private renderSelection(kind:'navigation'|'selection'):void {
    const previous = this.lastRenderedKeys;
    this.syncSelectionPresentation();

    const current = this.selection.keys;
    this.lastRenderedKeys = current;

    const changed = kind === 'navigation'
      ? previous.size > 1 && current.size !== previous.size
      : current.size !== previous.size || [...current].some((id) => !previous.has(id));

    if (changed) {
      this.announceSelection(current.size === 0 ? 'cleared' : 'selected');
    }
  }

  private syncSelectionPresentation():void {
    applySelectionPresentation(this.host.rootElement, this.selection.keys, this.host.descriptionId);
  }

  private announceSelection(key:'selected'|'cleared'|'not_selectable'|'range_unavailable'|'range_blocked'|'range_restarted'):void {
    void announce(this.selectionMessage(key), { politeness: 'polite' });
  }

  // The consumer's vocabulary: Backlogs says "work package", not "item".
  private selectionMessage(key:string):string {
    return I18n.t(`${this.host.announcementScope}.${key}`, { count: this.selection.size });
  }

  // Repaints whether or not prune dropped anything: a morph can strip or
  // preserve the marker attribute independently of the model.
  reconcile():void {
    this.selection.prune(liveOrderableKeys(this.host.rootElement));
    this.rebindAnchorList();
    this.renderSelection('selection');
  }

  // The anchor's list key is stamped when the anchor is set — drag *start*
  // for a drag — so a card dropped elsewhere still names its old list. Runs
  // after prune, so it only ever sees an anchor that still exists.
  private rebindAnchorList():void {
    const { anchor } = this.selection;
    if (!anchor) {
      return;
    }

    // Matched on type as well as id: ids collide across source tables.
    const element = orderedItemElements(this.host.rootElement)
      .find((item) => resolveItemId(item) === anchor.id && resolveItemType(item) === anchor.type);
    const candidate = element ? resolveCandidate(this.host.rootElement, element) : null;

    if (candidate) {
      this.selection.rebindAnchor(candidate.listKey);
    }
  }

  // Presentation only: a restored page brings its markup back under a fresh
  // orchestrator, whose model and render baseline are already empty.
  clearPresentation():void {
    applySelectionPresentation(this.host.rootElement, new Set(), this.host.descriptionId);
  }

  teardown():void {
    this.selection.clear();
    this.lastRenderedKeys = new Set();
    this.clearPresentation();
  }
}

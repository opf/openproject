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

import { Component, signal, viewChild } from '@angular/core';
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { vi } from 'vitest';
import {
  NativeDragSimulation,
  towardsEdgeOf,
} from 'core-common/drag-and-drop/testing/native-drag-simulation';
import { OpSortableListsItemDirective } from './sortable-lists-item.directive';
import { OpSortableListsListDirective } from './sortable-lists-list.directive';
import {
  OpSortableListsDirective,
  type SortableListsDropEvent,
  type SortableListsRemovedEvent,
} from './sortable-lists.directive';

// Deliberately does NOT `vi.mock` Pragmatic's autoscroll module: this suite
// observes the REAL implementation's own documented side effects, which is
// what makes the scroll-container assertions below meaningful.
//   - the scroll-fallback tests below assert on `data-auto-scrollable`, the
//     attribute Pragmatic's real `autoScrollForElements` sets on registration
//     and removes on cleanup (see `@atlaskit/pragmatic-drag-and-drop-auto-scroll`'s
//     `addScrollableAttribute`) — no interception needed to observe it.
//   - the `opSortableListsScrollContainer` suite further down already spies
//     on `console.warn` directly to see the real "not scrollable" warning.
const SCROLLABLE_ATTR = 'data-auto-scrollable';

// Behavioral suite for the directive group: scope resolution (collapsed vs.
// explicit lists, nested roots), the cross-list removed/drop ordering
// contract, and the completion/finalize → busy lifecycle. Single-root
// mechanics live in `sortable-lists.directive.spec.ts`.

describe('sortable-lists directive group behavior', () => {

  describe('single-list collapse (implicit list)', () => {
    @Component({
      imports: [OpSortableListsDirective, OpSortableListsItemDirective],
      template: `
        <div class="scroll-host" style="overflow: auto;">
          <div
            class="root"
            opSortableLists
            (opSortableListsDrop)="drops.push($event)"
            style="padding-bottom: 40px;"
          >
            @for (entry of items(); track entry.id) {
              <div
                class="item"
                [opSortableListsItem]="entry.id"
                [opSortableListsItemCanDrag]="entry.canDrag"
                style="height: 40px; width: 200px;"
              >{{ entry.id }}</div>
            }
          </div>
        </div>
      `,
    })
    class CollapseHostComponent {
      items = signal([
        { id: 'a', canDrag: true },
        { id: 'b', canDrag: true },
        { id: 'c', canDrag: true },
      ]);

      drops:SortableListsDropEvent[] = [];
    }

    let fixture:ComponentFixture<CollapseHostComponent>;
    let host:CollapseHostComponent;

    beforeEach(async () => {
      await TestBed.configureTestingModule({ imports: [CollapseHostComponent] }).compileComponents();
      fixture = TestBed.createComponent(CollapseHostComponent);
      host = fixture.componentInstance;
      fixture.detectChanges();
    });

    function root():HTMLElement {
      return (fixture.nativeElement as HTMLElement).querySelector('.root')!;
    }

    function item(index:number):HTMLElement {
      return (fixture.nativeElement as HTMLElement).querySelectorAll<HTMLElement>('.item')[index];
    }

    it('emits one drop event on the root proxy output and releases busy on complete', async () => {
      const simulation = new NativeDragSimulation(item(0));

      await simulation.start();
      await simulation.drop(item(2), towardsEdgeOf(item(2), 'bottom'));

      expect(host.drops).toHaveLength(1);
      expect(host.drops[0]).toMatchObject({
        sourceId: 'a', targetId: 'c', edge: 'bottom', axis: 'vertical',
      });
      expect(root().hasAttribute('data-sortable-lists-busy')).toBe(true);

      host.drops[0].complete(true);
      // `complete()` defers its own resolution by one microtask hop; one
      // `await` is enough for the busy release inside it to have run.
      await Promise.resolve();

      expect(root().hasAttribute('data-sortable-lists-busy')).toBe(false);
    });

    it('blocks drag start when opSortableListsItemCanDrag is false', async () => {
      host.items.set([
        { id: 'a', canDrag: false },
        { id: 'b', canDrag: true },
      ]);
      fixture.detectChanges();

      const simulation = new NativeDragSimulation(item(0));
      await simulation.start();

      expect(item(0).hasAttribute('data-dragging')).toBe(false);

      // The unblocked sibling still drags normally — proves the gate is
      // per-item, not a root-wide side effect.
      const allowed = new NativeDragSimulation(item(1));
      await allowed.start();
      expect(item(1).dataset.dragging).toBe('source');
      await allowed.cancel();
    });

    // `@for` tracks by id, so replacing the signal with the SAME ids in a new
    // order moves the existing DOM nodes rather than recreating them —
    // `registerItem` never re-runs. The engine's bounded-stickiness span
    // must therefore stay accurate from CURRENT rects, not registration order.
    it('keeps items draggable and the append span accurate after a track-by-id reorder', async () => {
      // Registration order a, b, c; reorder to visual order c, a, b, same ids.
      host.items.set([
        { id: 'c', canDrag: true },
        { id: 'a', canDrag: true },
        { id: 'b', canDrag: true },
      ]);
      fixture.detectChanges();

      const itemLabels = [...(fixture.nativeElement as HTMLElement).querySelectorAll<HTMLElement>('.item')]
        .map((el) => el.textContent);
      expect(itemLabels).toEqual(['c', 'a', 'b']);

      // Reorder still works post-churn, resolving via the real hovered
      // element rather than registration order.
      const reorder = new NativeDragSimulation(item(2));
      await reorder.start();
      await reorder.drop(item(0), towardsEdgeOf(item(0), 'top'));

      expect(host.drops.map(({ sourceId, targetId, edge }) => ({ sourceId, targetId, edge })))
        .toEqual([{ sourceId: 'b', targetId: 'c', edge: 'top' }]);
      // Same-list transactions settle on complete() alone — must release
      // busy before the next drag or later canDrag/canDrop checks short-circuit.
      host.drops[0].complete(true);
      await Promise.resolve();
      host.drops = [];

      // Dwell over the visually middle item ('a') to make it sticky, then
      // move to the root's native target while still squarely inside 'a'.
      const span = new NativeDragSimulation(item(2));
      await span.start();

      const middleItem = item(1); // visually 'a'
      const middleRect = middleItem.getBoundingClientRect();
      const midSpanPoint = { x: middleRect.left + middleRect.width / 2, y: middleRect.top + middleRect.height / 2 };

      await span.dragOver(middleItem, midSpanPoint);
      expect(middleItem.hasAttribute('data-drop-position')).toBe(true);

      await span.dragOver(root(), midSpanPoint);

      // The span is derived from every item's CURRENT rect, not registration
      // order, so 'a' correctly stays sticky via the root's native target.
      expect(middleItem.hasAttribute('data-drop-position')).toBe(true);
      expect(root().hasAttribute('data-drop-container')).toBe(false);

      // Beyond the visually last item ('b'), into the root's trailing padding.
      const lastVisualRect = item(2).getBoundingClientRect(); // visually 'b'
      const beyondVisualSpan = { x: midSpanPoint.x, y: lastVisualRect.bottom + 30 };
      await span.dragOver(root(), beyondVisualSpan);

      expect(middleItem.hasAttribute('data-drop-position')).toBe(false);
      expect(root().getAttribute('data-drop-container')).toBe('active');

      await span.drop(root(), beyondVisualSpan);

      expect(host.drops.map(({ sourceId, targetId, edge }) => ({ sourceId, targetId, edge })))
        .toEqual([{ sourceId: 'b', targetId: null, edge: null }]);
    });
  });

  describe('explicit root + list on the same element', () => {
    @Component({
      imports: [OpSortableListsDirective, OpSortableListsListDirective, OpSortableListsItemDirective],
      template: `
        <div class="scroll-host" style="overflow: auto;">
          <div class="root" opSortableLists opSortableListsList>
            @for (id of ids(); track id) {
              <div class="item" [opSortableListsItem]="id" style="height: 40px; width: 200px;">{{ id }}</div>
            }
          </div>
        </div>
      `,
    })
    class RootListSameElementHostComponent {
      ids = signal(['a', 'b', 'c']);

      rootDirective = viewChild.required(OpSortableListsDirective);

      listDirective = viewChild.required(OpSortableListsListDirective);
    }

    let fixture:ComponentFixture<RootListSameElementHostComponent>;
    let host:RootListSameElementHostComponent;

    beforeEach(async () => {
      await TestBed.configureTestingModule({ imports: [RootListSameElementHostComponent] }).compileComponents();
      fixture = TestBed.createComponent(RootListSameElementHostComponent);
      host = fixture.componentInstance;
      fixture.detectChanges();
    });

    function item(index:number):HTMLElement {
      return (fixture.nativeElement as HTMLElement).querySelectorAll<HTMLElement>('.item')[index];
    }

    it('routes drops to the list output; the root proxy stays silent', async () => {
      // Both directives share the same output name on the same host element,
      // so a template binding can't tell them apart; spy the instances directly.
      const rootSpy = vi.spyOn(host.rootDirective().opSortableListsDrop, 'emit');
      const listSpy = vi.spyOn(host.listDirective().opSortableListsDrop, 'emit');

      const simulation = new NativeDragSimulation(item(0));
      await simulation.start();
      await simulation.drop(item(2), towardsEdgeOf(item(2), 'bottom'));

      expect(rootSpy).not.toHaveBeenCalled();
      expect(listSpy).toHaveBeenCalledTimes(1);
      expect(listSpy.mock.calls[0][0]).toMatchObject({ sourceId: 'a', targetId: 'c', edge: 'bottom' });
    });
  });

  describe('two explicit lists sharing one root', () => {
    type LoggedEvent =
      | { type:'drop'; listId:'a'|'b'; event:SortableListsDropEvent }
      | { type:'removed'; listId:'a'|'b'; event:SortableListsRemovedEvent };

    // Type-predicate lookup, not an `as Extract<...>` cast: fails loudly if
    // the event was never recorded, instead of silently typing a miss as present.
    function findEvent<T extends LoggedEvent['type']>(
      events:LoggedEvent[],
      type:T,
    ):Extract<LoggedEvent, { type:T }> {
      const found = events.find((e):e is Extract<LoggedEvent, { type:T }> => e.type === type);
      if (!found) {
        throw new Error(`Expected a '${type}' event to have been recorded.`);
      }
      return found;
    }

    @Component({
      imports: [OpSortableListsDirective, OpSortableListsListDirective, OpSortableListsItemDirective],
      template: `
        <div class="scroll-host" style="overflow: auto;">
          <div class="root" opSortableLists>
            <div
              class="list-a"
              opSortableListsList
              opSortableListsListId="list-a"
              (opSortableListsDrop)="events.push({ type: 'drop', listId: 'a', event: $event })"
              (opSortableListsRemoved)="events.push({ type: 'removed', listId: 'a', event: $event })"
            >
              @for (id of idsA(); track id) {
                <div class="item" [opSortableListsItem]="id" style="height: 40px; width: 200px;">{{ id }}</div>
              }
            </div>

            <div
              class="list-b"
              opSortableListsList
              opSortableListsListId="list-b"
              (opSortableListsDrop)="events.push({ type: 'drop', listId: 'b', event: $event })"
              (opSortableListsRemoved)="events.push({ type: 'removed', listId: 'b', event: $event })"
            >
              @for (id of idsB(); track id) {
                <div class="item" [opSortableListsItem]="id" style="height: 40px; width: 200px;">{{ id }}</div>
              }
            </div>
          </div>
        </div>
      `,
    })
    class TwoListsHostComponent {
      idsA = signal(['a1', 'a2']);

      idsB = signal(['b1', 'b2']);

      events:LoggedEvent[] = [];
    }

    let fixture:ComponentFixture<TwoListsHostComponent>;
    let host:TwoListsHostComponent;

    beforeEach(async () => {
      await TestBed.configureTestingModule({ imports: [TwoListsHostComponent] }).compileComponents();
      fixture = TestBed.createComponent(TwoListsHostComponent);
      host = fixture.componentInstance;
      fixture.detectChanges();
    });

    function rootEl():HTMLElement {
      return (fixture.nativeElement as HTMLElement).querySelector('.root')!;
    }

    function itemIn(list:'list-a'|'list-b', index:number):HTMLElement {
      return (fixture.nativeElement as HTMLElement).querySelectorAll<HTMLElement>(`.${list} .item`)[index];
    }

    it('emits removed on the source list before drop on the target list, cross-list', async () => {
      const simulation = new NativeDragSimulation(itemIn('list-a', 0));

      await simulation.start();
      await simulation.drop(itemIn('list-b', 0), towardsEdgeOf(itemIn('list-b', 0), 'top'));

      expect(host.events.map((e) => e.type)).toEqual(['removed', 'drop']);

      const removed = findEvent(host.events, 'removed');
      const drop = findEvent(host.events, 'drop');
      expect(removed.listId).toBe('a');
      expect(drop.listId).toBe('b');
      expect(removed.event.itemId).toBe('a1');
      expect(removed.event.transactionId).toBe(drop.event.transactionId);

      // `finalize()` is a working no-arg source-side settlement call.
      drop.event.complete(true);
      await removed.event.completion;
      removed.event.finalize();
      await Promise.resolve();
      await Promise.resolve();

      expect(rootEl().hasAttribute('data-sortable-lists-busy')).toBe(false);
    });

    it('same-list drop emits drop only; removed is never called', async () => {
      const simulation = new NativeDragSimulation(itemIn('list-a', 0));

      await simulation.start();
      await simulation.drop(itemIn('list-a', 1), towardsEdgeOf(itemIn('list-a', 1), 'bottom'));

      expect(host.events).toHaveLength(1);
      expect(host.events[0]).toMatchObject({ type: 'drop', listId: 'a' });
    });

    it('holds busy through a pending cross-list completion and releases after finalize', async () => {
      const simulation = new NativeDragSimulation(itemIn('list-a', 0));

      await simulation.start();
      await simulation.drop(itemIn('list-b', 0), towardsEdgeOf(itemIn('list-b', 0), 'top'));

      expect(rootEl().hasAttribute('data-sortable-lists-busy')).toBe(true);

      const removed = findEvent(host.events, 'removed');
      const drop = findEvent(host.events, 'drop');

      // Target handler rejects the drop.
      drop.event.complete(false);
      await expect(removed.event.completion).resolves.toBe(false);

      // Target has settled; source has not finalized yet — still busy.
      expect(rootEl().hasAttribute('data-sortable-lists-busy')).toBe(true);

      removed.event.finalize();
      await Promise.resolve();
      await Promise.resolve();

      expect(rootEl().hasAttribute('data-sortable-lists-busy')).toBe(false);
    });
  });

  describe('dynamic first-list registration', () => {
    @Component({
      imports: [OpSortableListsDirective, OpSortableListsListDirective, OpSortableListsItemDirective],
      template: `
        <div class="scroll-host" style="overflow: auto;">
          <div class="root" opSortableLists (opSortableListsDrop)="rootDrops.push($event)">
            @if (explicit()) {
              <div
                class="list"
                opSortableListsList
                (opSortableListsDrop)="listDrops.push($event)"
              >
                @for (id of ids(); track id) {
                  <div class="item" [opSortableListsItem]="id" style="height: 40px; width: 200px;">{{ id }}</div>
                }
              </div>
            } @else {
              @for (id of ids(); track id) {
                <div class="item" [opSortableListsItem]="id" style="height: 40px; width: 200px;">{{ id }}</div>
              }
            }
          </div>
        </div>
      `,
    })
    class DynamicListHostComponent {
      explicit = signal(false);

      ids = signal(['a', 'b', 'c']);

      rootDrops:SortableListsDropEvent[] = [];

      listDrops:SortableListsDropEvent[] = [];
    }

    let fixture:ComponentFixture<DynamicListHostComponent>;
    let host:DynamicListHostComponent;

    beforeEach(async () => {
      await TestBed.configureTestingModule({ imports: [DynamicListHostComponent] }).compileComponents();
      fixture = TestBed.createComponent(DynamicListHostComponent);
      host = fixture.componentInstance;
      fixture.detectChanges();
    });

    function item(index:number):HTMLElement {
      return (fixture.nativeElement as HTMLElement).querySelectorAll<HTMLElement>('.item')[index];
    }

    async function dragFirstOntoLast():Promise<void> {
      const simulation = new NativeDragSimulation(item(0));
      await simulation.start();
      await simulation.drop(item(2), towardsEdgeOf(item(2), 'bottom'));
    }

    it('hands drops from the root proxy to the list output and back as the child toggles', async () => {
      // Same-list, so complete() alone releases busy — must be called
      // between drags or the root stays busy for the next one.
      async function settle(event:SortableListsDropEvent):Promise<void> {
        event.complete(true);
        await Promise.resolve();
      }

      // OFF: no explicit list yet — root is in implicit collapse mode.
      await dragFirstOntoLast();
      expect(host.rootDrops).toHaveLength(1);
      expect(host.listDrops).toHaveLength(0);
      await settle(host.rootDrops[0]);
      host.rootDrops = [];

      // ON: the explicit list registers, retiring the implicit list.
      host.explicit.set(true);
      fixture.detectChanges();

      await dragFirstOntoLast();
      expect(host.rootDrops).toHaveLength(0);
      expect(host.listDrops).toHaveLength(1);
      await settle(host.listDrops[0]);
      host.listDrops = [];

      // OFF again: the explicit list unregisters, and implicit collapse
      // resumes on the root element itself.
      host.explicit.set(false);
      fixture.detectChanges();

      await dragFirstOntoLast();
      expect(host.rootDrops).toHaveLength(1);
      expect(host.listDrops).toHaveLength(0);
    });
  });

  describe('nested roots', () => {
    // Two independent roots each need their own closest-scrollable-ancestor,
    // or both walks terminate on the same element and Pragmatic ends up with
    // two registrations on one node — see sortable-lists-engine.ts:142-149.
    @Component({
      imports: [OpSortableListsDirective, OpSortableListsItemDirective],
      template: `
        <div class="scroll-host" style="overflow: auto;">
          <div class="outer-root" opSortableLists (opSortableListsDrop)="outerDrops.push($event)">
            <div class="outer-item" opSortableListsItem="outer-a" style="height: 40px; width: 200px;">outer-a</div>

            <div class="inner-scroll-host" style="overflow: auto;">
              <div class="inner-root" opSortableLists (opSortableListsDrop)="innerDrops.push($event)">
                @for (id of innerIds(); track id) {
                  <div class="item" [opSortableListsItem]="id" style="height: 40px; width: 200px;">{{ id }}</div>
                }
              </div>
            </div>
          </div>
        </div>
      `,
    })
    class NestedRootsHostComponent {
      innerIds = signal(['b1', 'b2', 'b3']);

      outerDrops:SortableListsDropEvent[] = [];

      innerDrops:SortableListsDropEvent[] = [];
    }

    let fixture:ComponentFixture<NestedRootsHostComponent>;
    let host:NestedRootsHostComponent;

    beforeEach(async () => {
      await TestBed.configureTestingModule({ imports: [NestedRootsHostComponent] }).compileComponents();
      fixture = TestBed.createComponent(NestedRootsHostComponent);
      host = fixture.componentInstance;
      fixture.detectChanges();
    });

    function innerItem(index:number):HTMLElement {
      return (fixture.nativeElement as HTMLElement).querySelectorAll<HTMLElement>('.inner-root .item')[index];
    }

    it("resolves an inner root's items to the inner root; the outer root stays silent", async () => {
      const simulation = new NativeDragSimulation(innerItem(0));

      await simulation.start();
      await simulation.drop(innerItem(2), towardsEdgeOf(innerItem(2), 'bottom'));

      expect(host.innerDrops).toHaveLength(1);
      expect(host.innerDrops[0]).toMatchObject({ sourceId: 'b1', targetId: 'b3', edge: 'bottom' });
      expect(host.outerDrops).toHaveLength(0);
    });
  });

  describe('an inner root nested inside an outer explicit list', () => {
    // An item under the inner (collapsed) root must never adopt the outer
    // list's id — DI's nearest-list lookup does not stop at the inner root,
    // so without the ownership check it would register against the inner
    // engine under an id that engine never registered a list for.
    //
    // The inner wrapper also gives the inner root its own scrollable
    // ancestor, distinct from the outer root's, so the two don't collide on
    // one Pragmatic registration — see sortable-lists-engine.ts:142-149.
    @Component({
      imports: [OpSortableListsDirective, OpSortableListsListDirective, OpSortableListsItemDirective],
      template: `
        <div class="scroll-host" style="overflow: auto;">
          <div class="outer-root" opSortableLists>
            <div
              class="outer-list"
              opSortableListsList
              opSortableListsListId="outer-list"
              (opSortableListsDrop)="outerListDrops.push($event)"
              (opSortableListsRemoved)="outerListRemoved.push($event)"
            >
              <div class="inner-scroll-host" style="overflow: auto;">
                <div
                  class="inner-root"
                  opSortableLists
                  (opSortableListsDrop)="innerDrops.push($event)"
                  (opSortableListsRemoved)="innerRemoved.push($event)"
                  style="padding-bottom: 40px;"
                >
                  @for (id of innerIds(); track id) {
                    <div class="item" [opSortableListsItem]="id" style="height: 40px; width: 200px;">{{ id }}</div>
                  }
                </div>
              </div>
            </div>
          </div>
        </div>
      `,
    })
    class NestedRootOwnershipHostComponent {
      innerIds = signal(['b1', 'b2', 'b3']);

      outerListDrops:SortableListsDropEvent[] = [];

      outerListRemoved:SortableListsRemovedEvent[] = [];

      innerDrops:SortableListsDropEvent[] = [];

      innerRemoved:SortableListsRemovedEvent[] = [];
    }

    let fixture:ComponentFixture<NestedRootOwnershipHostComponent>;
    let host:NestedRootOwnershipHostComponent;

    beforeEach(async () => {
      await TestBed.configureTestingModule({ imports: [NestedRootOwnershipHostComponent] }).compileComponents();
      fixture = TestBed.createComponent(NestedRootOwnershipHostComponent);
      host = fixture.componentInstance;
      fixture.detectChanges();
    });

    function innerRootEl():HTMLElement {
      return (fixture.nativeElement as HTMLElement).querySelector('.inner-root')!;
    }

    function innerItem(index:number):HTMLElement {
      return (fixture.nativeElement as HTMLElement).querySelectorAll<HTMLElement>('.inner-root .item')[index];
    }

    it('resolves a drop into the inner container space as a same-list append on the inner root', async () => {
      const last = innerItem(2);
      const simulation = new NativeDragSimulation(innerItem(0));

      await simulation.start();
      // The inner root's own trailing container space (below the last item,
      // still inside its padding) — a container-level append, not an item target.
      const lastRect = last.getBoundingClientRect();
      const appendPoint = { x: lastRect.left + lastRect.width / 2, y: lastRect.bottom + 20 };
      await simulation.drop(innerRootEl(), appendPoint);

      // A mismatched list id would misclassify this as a cross-list move and
      // emit `removed` for an item that never left its list.
      expect(host.innerDrops).toHaveLength(1);
      expect(host.innerDrops[0]).toMatchObject({ sourceId: 'b1', targetId: null, edge: null });
      expect(host.innerRemoved).toHaveLength(0);
      expect(host.outerListDrops).toHaveLength(0);
      expect(host.outerListRemoved).toHaveLength(0);

      // Same-list transactions settle on complete() alone; a mismatched list
      // id would misroute through the cross-list path, needing finalize()
      // too, and leave the inner root stuck busy since nothing here calls it.
      host.innerDrops[0].complete(true);
      await Promise.resolve();

      expect(innerRootEl().hasAttribute('data-sortable-lists-busy')).toBe(false);
    });
  });

  describe('root teardown', () => {
    @Component({
      imports: [OpSortableListsDirective, OpSortableListsListDirective, OpSortableListsItemDirective],
      template: `
        <div class="scroll-host" style="overflow: auto;">
          <div class="root" opSortableLists opSortableListsList>
            @for (id of ids(); track id) {
              <div class="item" [opSortableListsItem]="id" style="height: 40px; width: 200px;">{{ id }}</div>
            }
          </div>
        </div>
      `,
    })
    class TeardownHostComponent {
      ids = signal(['a', 'b', 'c']);

      rootDirective = viewChild.required(OpSortableListsDirective);
    }

    it('does not resurrect the implicit list once root teardown has begun', async () => {
      // Root and its one explicit list share a host element, so destroying
      // this fixture tears both down in the same pass — the explicit list
      // is last to detach, so `attachList`'s cleanup would otherwise call
      // `registerImplicitList()` against an already-destroying engine.
      await TestBed.configureTestingModule({ imports: [TeardownHostComponent] }).compileComponents();
      const fixture = TestBed.createComponent(TeardownHostComponent);
      const host = fixture.componentInstance;
      fixture.detectChanges();

      // Spies the private method directly: the engine already no-ops a
      // post-destroy `registerList` (defense in depth), so a black-box
      // assertion would pass regardless of whether the directive still tries.
      const root = host.rootDirective() as unknown as { registerImplicitList():void };
      const registerImplicitList = vi.spyOn(root, 'registerImplicitList');

      fixture.destroy();

      expect(registerImplicitList).not.toHaveBeenCalled();
    });
  });

  describe('opSortableListsScrollContainer', () => {
    const NOT_SCROLLABLE_WARNING = 'not to be scrollable';

    function warnedNotScrollable(calls:unknown[][]):boolean {
      return calls.some((call) => typeof call[0] === 'string' && call[0].includes(NOT_SCROLLABLE_WARNING));
    }

    @Component({
      imports: [OpSortableListsDirective, OpSortableListsItemDirective],
      template: `
        <div class="root" opSortableLists>
          @for (id of ids(); track id) {
            <div class="item" [opSortableListsItem]="id" style="height: 40px; width: 200px;">{{ id }}</div>
          }
        </div>
      `,
    })
    class PlainRootHostComponent {
      ids = signal(['a', 'b', 'c']);
    }

    // `.scroll-target` is a plain sibling, not an ancestor of `.root`, so
    // honoring it can only be the explicit input taking effect — never the
    // closest-scrollable-ancestor fallback.
    @Component({
      imports: [OpSortableListsDirective, OpSortableListsItemDirective],
      template: `
        <div class="root" opSortableLists [opSortableListsScrollContainer]="scrollTarget">
          @for (id of ids(); track id) {
            <div class="item" [opSortableListsItem]="id" style="height: 40px; width: 200px;">{{ id }}</div>
          }
        </div>
        <div class="scroll-target" #scrollTarget style="overflow: auto; height: 100px; width: 100px;"></div>
      `,
    })
    class ScrollContainerInputHostComponent {
      ids = signal(['a', 'b', 'c']);
    }

    @Component({
      imports: [OpSortableListsDirective, OpSortableListsItemDirective],
      template: `
        <div class="scroll-wrapper" style="overflow: auto; height: 100px;">
          <div class="root" opSortableLists>
            @for (id of ids(); track id) {
              <div class="item" [opSortableListsItem]="id" style="height: 40px; width: 200px;">{{ id }}</div>
            }
          </div>
        </div>
      `,
    })
    class ScrollableAncestorHostComponent {
      ids = signal(['a', 'b', 'c']);
    }

    it('warns when the collapsed root has neither an input nor a scrollable ancestor', async () => {
      const warn = vi.spyOn(console, 'warn').mockImplementation(() => undefined);
      try {
        await TestBed.configureTestingModule({ imports: [PlainRootHostComponent] }).compileComponents();
        const fixture = TestBed.createComponent(PlainRootHostComponent);
        fixture.detectChanges();

        expect(warnedNotScrollable(warn.mock.calls)).toBe(true);
      } finally {
        warn.mockRestore();
      }
    });

    it('honors an explicit scroll container input, silencing that warning', async () => {
      const warn = vi.spyOn(console, 'warn').mockImplementation(() => undefined);
      try {
        await TestBed.configureTestingModule({ imports: [ScrollContainerInputHostComponent] }).compileComponents();
        const fixture = TestBed.createComponent(ScrollContainerInputHostComponent);
        fixture.detectChanges();

        expect(warnedNotScrollable(warn.mock.calls)).toBe(false);
      } finally {
        warn.mockRestore();
      }
    });

    it('falls back to the closest scrollable ancestor when no input is given', async () => {
      const warn = vi.spyOn(console, 'warn').mockImplementation(() => undefined);
      try {
        await TestBed.configureTestingModule({ imports: [ScrollableAncestorHostComponent] }).compileComponents();
        const fixture = TestBed.createComponent(ScrollableAncestorHostComponent);
        fixture.detectChanges();

        expect(warnedNotScrollable(warn.mock.calls)).toBe(false);
      } finally {
        warn.mockRestore();
      }
    });
  });

  describe('opSortableListsAxis', () => {
    // The engine captures the placement axis once, at root creation (see
    // `createSortableRoot`), so a horizontal vs. default root needs two
    // separate directive instances — a signal input flip on one instance
    // cannot retroactively change what its engine root was created with.

    // Fixed-width inline chips so a horizontal drag resolves a left/right
    // edge — a vertical-axis layout (block rows) would never produce one.
    @Component({
      imports: [OpSortableListsDirective, OpSortableListsItemDirective],
      template: `
        <div class="scroll-host" style="overflow: auto;">
          <div
            class="root"
            opSortableLists
            [opSortableListsAxis]="'horizontal'"
            (opSortableListsDrop)="drops.push($event)"
            style="white-space: nowrap;"
          >
            @for (id of ids(); track id) {
              <div
                class="item"
                [opSortableListsItem]="id"
                style="display: inline-block; width: 40px; height: 20px;"
              >{{ id }}</div>
            }
          </div>
        </div>
      `,
    })
    class HorizontalAxisHostComponent {
      ids = signal(['a', 'b']);

      drops:SortableListsDropEvent[] = [];
    }

    @Component({
      imports: [OpSortableListsDirective, OpSortableListsItemDirective],
      template: `
        <div class="scroll-host" style="overflow: auto;">
          <div class="root" opSortableLists (opSortableListsDrop)="drops.push($event)">
            @for (id of ids(); track id) {
              <div class="item" [opSortableListsItem]="id" style="height: 40px; width: 200px;">{{ id }}</div>
            }
          </div>
        </div>
      `,
    })
    class DefaultAxisHostComponent {
      ids = signal(['a', 'b']);

      drops:SortableListsDropEvent[] = [];
    }

    function item(fixture:ComponentFixture<unknown>, index:number):HTMLElement {
      return (fixture.nativeElement as HTMLElement).querySelectorAll<HTMLElement>('.item')[index];
    }

    it("emits drop events with the root's horizontal placement axis", async () => {
      await TestBed.configureTestingModule({ imports: [HorizontalAxisHostComponent] }).compileComponents();
      const fixture = TestBed.createComponent(HorizontalAxisHostComponent);
      const host = fixture.componentInstance;
      fixture.detectChanges();

      const simulation = new NativeDragSimulation(item(fixture, 0));
      await simulation.start();
      await simulation.drop(item(fixture, 1), towardsEdgeOf(item(fixture, 1), 'right'));

      expect(host.drops).toHaveLength(1);
      expect(host.drops[0]).toMatchObject({ axis: 'horizontal' });
    });

    it('a default root (no axis input) emits vertical', async () => {
      await TestBed.configureTestingModule({ imports: [DefaultAxisHostComponent] }).compileComponents();
      const fixture = TestBed.createComponent(DefaultAxisHostComponent);
      const host = fixture.componentInstance;
      fixture.detectChanges();

      const simulation = new NativeDragSimulation(item(fixture, 0));
      await simulation.start();
      await simulation.drop(item(fixture, 1), towardsEdgeOf(item(fixture, 1), 'bottom'));

      expect(host.drops).toHaveLength(1);
      expect(host.drops[0]).toMatchObject({ axis: 'vertical' });
    });
  });

  describe('explicit-list scroll-container fallback', () => {
    // Three explicit lists sharing one root: `list-scrollable` is itself a
    // valid scroll target; `list-a`/`list-b` are not and share the same
    // scrollable ancestor — proving both the per-list fallback and the
    // engine's root-level dedupe (one live registration for the shared
    // ancestor, not two).
    @Component({
      imports: [OpSortableListsDirective, OpSortableListsListDirective, OpSortableListsItemDirective],
      template: `
        <div
          class="scrollable-list"
          opSortableLists
          opSortableListsList
          style="overflow: auto; height: 100px;"
        >
          <div class="item" opSortableListsItem="s1" style="height: 40px; width: 200px;">s1</div>
        </div>

        <div class="ancestor" style="overflow: auto; height: 200px;">
          <div class="root" opSortableLists>
            <div class="list-a" opSortableListsList opSortableListsListId="list-a">
              <div class="item" opSortableListsItem="a1" style="height: 40px; width: 200px;">a1</div>
            </div>
            <div class="list-b" opSortableListsList opSortableListsListId="list-b">
              <div class="item" opSortableListsItem="b1" style="height: 40px; width: 200px;">b1</div>
            </div>
          </div>
        </div>
      `,
    })
    class ScrollFallbackHostComponent {}

    let fixture:ComponentFixture<ScrollFallbackHostComponent>;
    let warn:ReturnType<typeof vi.spyOn>;

    beforeEach(async () => {
      warn = vi.spyOn(console, 'warn').mockImplementation(() => undefined);
      await TestBed.configureTestingModule({ imports: [ScrollFallbackHostComponent] }).compileComponents();
      fixture = TestBed.createComponent(ScrollFallbackHostComponent);
      fixture.detectChanges();
    });

    afterEach(() => { warn.mockRestore(); });

    function elementFor(selector:string):Element {
      return (fixture.nativeElement as HTMLElement).querySelector(selector)!;
    }

    it('a scrollable explicit list registers itself as its own scroll container', () => {
      const scrollableList = elementFor('.scrollable-list');
      expect(scrollableList.hasAttribute(SCROLLABLE_ATTR)).toBe(true);
    });

    it('a non-scrollable explicit list registers its nearest scrollable ancestor', () => {
      const ancestor = elementFor('.ancestor');
      const listA = elementFor('.list-a');

      expect(listA.hasAttribute(SCROLLABLE_ATTR)).toBe(false);
      expect(ancestor.hasAttribute(SCROLLABLE_ATTR)).toBe(true);
    });

    it('two non-scrollable sibling lists sharing one ancestor yield one live registration', () => {
      const ancestor = elementFor('.ancestor');
      expect(ancestor.hasAttribute(SCROLLABLE_ATTR)).toBe(true);

      // The engine's own dedupe (`scrollRegistrations`, keyed by element in
      // `sortable-lists-engine.ts`) acquires the shared ancestor once and
      // unions axes on top of the existing registration rather than
      // registering it again. Pragmatic's real implementation warns via
      // console.warn when the same element is registered twice without an
      // intervening cleanup, so that warning's absence confirms there is
      // exactly one live registration on the ancestor, not two.
      const warnedTwice = (warn.mock.calls as unknown[][]).some(
        (call) => typeof call[0] === 'string' && call[0].includes('already registered'),
      );
      expect(warnedTwice).toBe(false);
    });
  });
});

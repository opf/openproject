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

import { vi } from 'vitest';
import {
  NativeDragSimulation,
  centerOf,
  towardsEdgeOf,
} from 'core-common/drag-and-drop/testing/native-drag-simulation';
import type {
  createSortableRoot as createSortableRootFn,
  SortableDropIntent,
  SortableDropTransaction,
  SortableSource,
} from './sortable-lists-engine';

// `doMock` is not hoisted, so this initialises before the factory below runs
// and a plain const does the job `vi.hoisted()` used to.
const autoScrollRegistrations:{
  element:Element;
  getAllowedAxis:() => string;
  cleanup:() => void;
  cleaned:boolean;
}[] = [];

vi.doMock('@atlaskit/pragmatic-drag-and-drop-auto-scroll/element', () => ({
  autoScrollForElements: (args:{ element:Element; getAllowedAxis:() => string }) => {
    const entry = {
      element: args.element,
      getAllowedAxis: args.getAllowedAxis,
      cleaned: false,
      cleanup: () => undefined,
    };
    entry.cleanup = () => { entry.cleaned = true; };
    autoScrollRegistrations.push(entry);
    return entry.cleanup;
  },
}));

let createSortableRoot:typeof createSortableRootFn;

const liveRegistrations = () => autoScrollRegistrations.filter((r) => !r.cleaned);

function buildList(items:string[]):{ root:HTMLElement; rows:HTMLElement[] } {
  const root = document.createElement('div');
  const rows = items.map((id) => {
    const row = document.createElement('div');
    row.style.cssText = 'height:20px;';
    row.textContent = id;
    root.appendChild(row);
    return row;
  });
  document.body.appendChild(root);
  return { root, rows };
}

// A list rendered as its own element inside a wrapping root, for cross-list
// scenarios where the root spans multiple `registerList` instances.
function buildListIn(root:HTMLElement, items:string[]):{ element:HTMLElement; rows:HTMLElement[] } {
  const element = document.createElement('div');
  const rows = items.map((id) => {
    const row = document.createElement('div');
    row.style.cssText = 'height:20px;';
    row.textContent = id;
    element.appendChild(row);
    return row;
  });
  root.appendChild(element);
  return { element, rows };
}

// A horizontal list of fixed-width chips, for axis:'horizontal' scenarios.
function buildHorizontalList(items:string[]):{ root:HTMLElement; chips:HTMLElement[] } {
  const root = document.createElement('div');
  root.style.cssText = 'white-space:nowrap;';
  const chips = items.map((id) => {
    const chip = document.createElement('div');
    chip.style.cssText = 'display:inline-block; width:40px; height:20px;';
    chip.textContent = id;
    root.appendChild(chip);
    return chip;
  });
  document.body.appendChild(root);
  return { root, chips };
}

// A horizontal list of fixed-width chips inside a fixed-width flex-wrap
// container, wrapping onto multiple rows — like the autocompleter's chips.
function buildWrappingHorizontalList(items:string[], containerWidth:number):{ root:HTMLElement; chips:HTMLElement[] } {
  const root = document.createElement('div');
  root.style.cssText = `display:flex; flex-wrap:wrap; width:${containerWidth}px; padding-bottom:60px;`;
  const chips = items.map((id) => {
    const chip = document.createElement('div');
    chip.style.cssText = 'width:40px; height:20px; margin:2px;';
    chip.textContent = id;
    root.appendChild(chip);
    return chip;
  });
  document.body.appendChild(root);
  return { root, chips };
}

// The card view's production geometry: a CSS Grid of fixed tracks, offset
// from the viewport origin. An incomplete last row leaves real empty tracks
// rather than the ragged tail flex-wrap gives. The leading padding gives the
// list blank space of its own to the left of every card, so a point there is
// physically inside the root rather than merely dispatched at it.
function buildCardGrid(items:string[], columns:number):{ root:HTMLElement; cards:HTMLElement[] } {
  const root = document.createElement('div');
  root.style.cssText = `display:grid; grid-template-columns:repeat(${columns}, 100px); gap:10px; margin:100px 0 0 100px; padding-left:60px; width:max-content;`;
  const cards = items.map((id) => {
    const card = document.createElement('div');
    card.style.cssText = 'height:40px;';
    card.textContent = id;
    root.appendChild(card);
    return card;
  });
  document.body.appendChild(root);
  return { root, cards };
}

describe('createSortableRoot', () => {
  let cleanupFns:(() => void)[] = [];

  beforeAll(async () => {
    ({ createSortableRoot } = await import('./sortable-lists-engine'));
  });

  beforeEach(() => { autoScrollRegistrations.length = 0; });

  afterEach(() => {
    cleanupFns.forEach((fn) => fn());
    cleanupFns = [];
    document.body.replaceChildren();
  });

  function setup(items:string[] = ['a', 'b', 'c'], opts:{ accepts?:(args:{ source:SortableSource }) => boolean } = {}) {
    const { root, rows } = buildList(items);
    const intents:SortableDropIntent[] = [];
    const cancels:SortableSource[] = [];
    const transactions:SortableDropTransaction[] = [];

    const sortableRoot = createSortableRoot({
      element: root,
      onDrop: (transaction) => {
        intents.push(transaction.intent);
        transactions.push(transaction);
      },
      onCancel: (source) => cancels.push(source),
    });

    const listCleanup = sortableRoot.registerList({ element: root, listId: 'l1', accepts: opts.accepts });
    const itemCleanups = rows.map((row, index) => sortableRoot.registerItem({
      element: row,
      itemId: items[index],
      listId: 'l1',
    }));

    cleanupFns.push(listCleanup, ...itemCleanups, () => sortableRoot.destroy());

    return {
      root, rows, intents, cancels, transactions, sortableRoot,
    };
  }

  // Two lists ('l1', 'l2') sharing one root, for cross-list transaction
  // scenarios (busy gating, `accepts`, settlement across list boundaries).
  function setupTwoLists(opts:{
    itemsA?:string[];
    itemsB?:string[];
    acceptsB?:(args:{ source:SortableSource }) => boolean;
  } = {}) {
    const itemsA = opts.itemsA ?? ['a1', 'a2'];
    const itemsB = opts.itemsB ?? ['b1', 'b2'];

    const root = document.createElement('div');
    document.body.appendChild(root);
    const listA = buildListIn(root, itemsA);
    const listB = buildListIn(root, itemsB);

    const intents:SortableDropIntent[] = [];
    const transactions:SortableDropTransaction[] = [];

    const sortableRoot = createSortableRoot({
      element: root,
      onDrop: (transaction) => {
        intents.push(transaction.intent);
        transactions.push(transaction);
      },
    });

    const cleanupA = sortableRoot.registerList({ element: listA.element, listId: 'l1' });
    const cleanupB = sortableRoot.registerList({ element: listB.element, listId: 'l2', accepts: opts.acceptsB });
    const itemCleanupsA = listA.rows.map((row, index) => sortableRoot.registerItem({
      element: row,
      itemId: itemsA[index],
      listId: 'l1',
    }));
    const itemCleanupsB = listB.rows.map((row, index) => sortableRoot.registerItem({
      element: row,
      itemId: itemsB[index],
      listId: 'l2',
    }));

    cleanupFns.push(cleanupA, cleanupB, ...itemCleanupsA, ...itemCleanupsB, () => sortableRoot.destroy());

    return {
      root, listA, listB, intents, transactions, sortableRoot,
    };
  }

  it('resolves a bottom-edge item drop to exactly one intent', async () => {
    const { rows, intents } = setup();
    const simulation = new NativeDragSimulation(rows[0]);

    await simulation.start();
    await simulation.drop(rows[2], towardsEdgeOf(rows[2], 'bottom'));

    expect(intents).toEqual([{
      sourceId: 'a',
      sourceListId: 'l1',
      targetListId: 'l1',
      targetItemId: 'c',
      edge: 'bottom',
      axis: 'vertical',
    }]);
  });

  it('resolves a drop on container space to an append intent', async () => {
    const { root, rows, intents } = setup();
    root.style.cssText = 'padding-bottom:40px;';
    const simulation = new NativeDragSimulation(rows[0]);
    const rootRect = root.getBoundingClientRect();
    const belowRows = { x: rootRect.left + rootRect.width / 2, y: rootRect.bottom - 5 };

    await simulation.start();
    await simulation.drop(root, belowRows);

    expect(intents).toEqual([{
      sourceId: 'a',
      sourceListId: 'l1',
      targetListId: 'l1',
      targetItemId: null,
      edge: null,
      axis: 'vertical',
    }]);
  });

  it('self-drop produces no intent', async () => {
    const { rows, intents } = setup();
    const simulation = new NativeDragSimulation(rows[1]);

    await simulation.start();
    await simulation.drop(rows[1], centerOf(rows[1]));

    expect(intents).toEqual([]);
  });

  it('drop outside every registered list cancels', async () => {
    const { rows, intents, cancels } = setup();
    const outside = document.createElement('div');
    outside.style.cssText = 'position:fixed; top:500px; left:500px; width:50px; height:50px;';
    document.body.appendChild(outside);
    const simulation = new NativeDragSimulation(rows[0]);

    await simulation.start();
    await simulation.drop(outside, centerOf(outside));

    expect(cancels).toEqual([{ itemId: 'a', listId: 'l1', element: rows[0] }]);
    expect(intents).toEqual([]);
  });

  it('writes the dragging and indicator attributes', async () => {
    const { rows } = setup();
    const simulation = new NativeDragSimulation(rows[0]);

    await simulation.start();
    expect(rows[0].dataset.dragging).toBe('source');

    await simulation.dragOver(rows[2], towardsEdgeOf(rows[2], 'bottom'));
    expect(rows[2].getAttribute('data-drop-position')).toBe('bottom');
    expect(rows[2].getAttribute('data-drop-position-owner')).toBe('c');

    await simulation.drop(rows[2], towardsEdgeOf(rows[2], 'bottom'));

    expect(rows[0].hasAttribute('data-dragging')).toBe(false);
    expect(rows[2].hasAttribute('data-drop-position')).toBe(false);
  });

  it('data-drop-container is active only for a list-only target', async () => {
    const { root, rows } = setup();
    root.style.cssText = 'padding-bottom:40px;';
    const simulation = new NativeDragSimulation(rows[0]);

    await simulation.start();

    await simulation.dragOver(rows[2], towardsEdgeOf(rows[2], 'bottom'));
    expect(root.hasAttribute('data-drop-container')).toBe(false);

    const rootRect = root.getBoundingClientRect();
    const belowRows = { x: rootRect.left + rootRect.width / 2, y: rootRect.bottom - 5 };
    await simulation.dragOver(root, belowRows);
    expect(root.getAttribute('data-drop-container')).toBe('active');
    expect(rows[2].hasAttribute('data-drop-position')).toBe(false);

    await simulation.cancel();
  });

  it('suppresses the drop indicator while hovering the drag source itself', async () => {
    const { rows } = setup();
    const simulation = new NativeDragSimulation(rows[0]);

    await simulation.start();
    expect(rows[0].dataset.dragging).toBe('source');

    // The row is still a valid drop target (canDrop must accept self), but
    // must not render a drop-position line on itself.
    await simulation.dragOver(rows[0], centerOf(rows[0]));

    expect(rows[0].dataset.dragging).toBe('source');
    expect(rows[0].hasAttribute('data-drop-position')).toBe(false);
    expect(rows[0].hasAttribute('data-drop-position-owner')).toBe(false);

    await simulation.cancel();
  });

  it('destroy is idempotent and unregisters every registration', async () => {
    const { rows, intents, sortableRoot } = setup();

    expect(() => {
      sortableRoot.destroy();
      sortableRoot.destroy();
    }).not.toThrow();

    const simulation = new NativeDragSimulation(rows[0]);
    await simulation.start();
    await simulation.drop(rows[2], towardsEdgeOf(rows[2], 'bottom'));

    expect(intents).toEqual([]);
  });

  describe('teardown', () => {
    it('destroying with a pending transaction clears busy and allows a fresh root to drag', async () => {
      const { root, rows, transactions, sortableRoot } = setup();
      const simulation = new NativeDragSimulation(rows[0]);

      await simulation.start();
      await simulation.drop(rows[2], towardsEdgeOf(rows[2], 'bottom'));
      expect(root.getAttribute('data-sortable-lists-busy')).toBe('true');
      // Deliberately never completed nor finalized — a real teardown race
      // (e.g. Angular tearing down mid-drop) can leave a transaction pending.
      expect(transactions).toHaveLength(1);

      sortableRoot.destroy();
      expect(root.hasAttribute('data-sortable-lists-busy')).toBe(false);

      // A fresh engine bound to the same element must not read the busy
      // attribute (which lives on the shared DOM node) as stranded.
      const freshIntents:SortableDropIntent[] = [];
      const freshRoot = createSortableRoot({
        element: root,
        onDrop: (transaction) => freshIntents.push(transaction.intent),
      });
      const freshListCleanup = freshRoot.registerList({ element: root, listId: 'l1' });
      const freshItemCleanups = rows.map((row, index) => freshRoot.registerItem({
        element: row,
        itemId: ['a', 'b', 'c'][index],
        listId: 'l1',
      }));
      cleanupFns.push(freshListCleanup, ...freshItemCleanups, () => freshRoot.destroy());

      const freshSimulation = new NativeDragSimulation(rows[0]);
      await freshSimulation.start();
      await freshSimulation.drop(rows[2], towardsEdgeOf(rows[2], 'bottom'));

      expect(freshIntents).toEqual([{
        sourceId: 'a', sourceListId: 'l1', targetListId: 'l1', targetItemId: 'c', edge: 'bottom', axis: 'vertical',
      }]);
    });

    it('registerList and registerItem are inert no-ops after destroy', async () => {
      const { root, rows, sortableRoot } = setup();

      sortableRoot.destroy();

      const warn = vi.spyOn(console, 'warn').mockImplementation(() => undefined);
      try {
        const lateListCleanup = sortableRoot.registerList({ element: root, listId: 'late' });
        const lateItemCleanup = sortableRoot.registerItem({ element: rows[0], itemId: 'late-a', listId: 'late' });

        expect(() => {
          lateListCleanup();
          lateItemCleanup();
        }).not.toThrow();

        // A real registration would attach a Pragmatic autoscroll adapter,
        // which warns on this non-scrollable root — its absence proves
        // nothing was registered.
        expect(warn).not.toHaveBeenCalled();

        const simulation = new NativeDragSimulation(rows[0]);
        await simulation.start();
        await simulation.drop(rows[2], towardsEdgeOf(rows[2], 'bottom'));

        expect(rows[0].hasAttribute('data-dragging')).toBe(false);
      } finally {
        warn.mockRestore();
      }
    });
  });

  describe('transaction lifecycle', () => {
    it('defers completion resolution past a synchronous complete() call', async () => {
      const { root, rows } = buildList(['a', 'b', 'c']);
      const order:string[] = [];

      const sortableRoot = createSortableRoot({
        element: root,
        onDrop: (transaction) => {
          // Attach before completing, so the reaction is scheduled the
          // moment the transaction actually resolves.
          void transaction.completion.then(() => order.push('completion'));
          transaction.complete(true);
          // Queued after complete() in the same synchronous callback — only
          // proves the deferral if complete() doesn't resolve eagerly.
          queueMicrotask(() => order.push('queued-after-complete'));
        },
      });
      const listCleanup = sortableRoot.registerList({ element: root, listId: 'l1' });
      const itemCleanups = rows.map((row, index) => sortableRoot.registerItem({
        element: row,
        itemId: ['a', 'b', 'c'][index],
        listId: 'l1',
      }));
      cleanupFns.push(listCleanup, ...itemCleanups, () => sortableRoot.destroy());

      const simulation = new NativeDragSimulation(rows[0]);
      await simulation.start();
      await simulation.drop(rows[2], towardsEdgeOf(rows[2], 'bottom'));

      // complete() defers its own resolution by one microtask hop, so the
      // microtask queued right after it in onDrop still runs first.
      expect(order).toEqual(['queued-after-complete', 'completion']);
    });

    it('complete is idempotent; the first call wins', async () => {
      const { rows, transactions } = setup();
      const simulation = new NativeDragSimulation(rows[0]);

      await simulation.start();
      await simulation.drop(rows[2], towardsEdgeOf(rows[2], 'bottom'));

      const transaction = transactions[0];
      transaction.complete(true);
      transaction.complete(false);

      await expect(transaction.completion).resolves.toBe(true);
    });

    it('finalize is idempotent', async () => {
      const { root, rows, transactions } = setup();
      const simulation = new NativeDragSimulation(rows[0]);

      await simulation.start();
      await simulation.drop(rows[2], towardsEdgeOf(rows[2], 'bottom'));

      const transaction = transactions[0];

      expect(() => {
        transaction.finalize();
        transaction.finalize();
      }).not.toThrow();

      transaction.complete(true);
      await transaction.completion;

      expect(root.hasAttribute('data-sortable-lists-busy')).toBe(false);
    });

    it('busy gates a second drag until both sides settle', async () => {
      const { listA, listB, root, transactions } = setupTwoLists();

      const simulation = new NativeDragSimulation(listA.rows[0]);
      await simulation.start();
      await simulation.drop(listB.rows[0], towardsEdgeOf(listB.rows[0], 'top'));

      expect(root.getAttribute('data-sortable-lists-busy')).toBe('true');
      expect(transactions).toHaveLength(1);
      const transaction = transactions[0];

      // A second drag attempt while busy resolves no intent.
      const second = new NativeDragSimulation(listA.rows[1]);
      await second.start();
      await second.drop(listB.rows[1], towardsEdgeOf(listB.rows[1], 'top'));
      expect(transactions).toHaveLength(1);

      // Target side settles, source side does not: still busy, still gated.
      transaction.complete(true);
      await transaction.completion;
      expect(root.getAttribute('data-sortable-lists-busy')).toBe('true');

      const third = new NativeDragSimulation(listA.rows[1]);
      await third.start();
      await third.drop(listB.rows[1], towardsEdgeOf(listB.rows[1], 'top'));
      expect(transactions).toHaveLength(1);

      // Source side finalizes: busy releases and dragging works again.
      transaction.finalize();
      await Promise.resolve();
      await Promise.resolve();
      expect(root.hasAttribute('data-sortable-lists-busy')).toBe(false);

      const fourth = new NativeDragSimulation(listA.rows[1]);
      await fourth.start();
      await fourth.drop(listB.rows[1], towardsEdgeOf(listB.rows[1], 'top'));
      expect(transactions).toHaveLength(2);
    });

    it('same-list transactions settle on complete alone', async () => {
      const { root, rows, transactions } = setup();
      const simulation = new NativeDragSimulation(rows[0]);

      await simulation.start();
      await simulation.drop(rows[2], towardsEdgeOf(rows[2], 'bottom'));

      expect(root.getAttribute('data-sortable-lists-busy')).toBe('true');

      const transaction = transactions[0];
      transaction.complete(true);
      await transaction.completion;

      expect(root.hasAttribute('data-sortable-lists-busy')).toBe(false);
    });

    it('resolves a cross-list drop intent', async () => {
      const { listA, listB, transactions } = setupTwoLists();

      const simulation = new NativeDragSimulation(listA.rows[0]);
      await simulation.start();
      await simulation.drop(listB.rows[0], towardsEdgeOf(listB.rows[0], 'top'));

      expect(transactions).toHaveLength(1);
      expect(transactions[0].intent).toMatchObject({
        sourceListId: 'l1',
        targetListId: 'l2',
      });

      // Settle explicitly so the 10s diagnostic timer doesn't leak past this test.
      const transaction = transactions[0];
      transaction.complete(true);
      transaction.finalize();
      await transaction.completion;
    });

    it('accepts gates both the item and container drop targets of the list', async () => {
      const { listA, listB, transactions } = setupTwoLists({ acceptsB: () => false });

      const simulation = new NativeDragSimulation(listA.rows[0]);
      await simulation.start();

      // Mid-drag: no indicator on the rejected list's item target.
      await simulation.dragOver(listB.rows[0], towardsEdgeOf(listB.rows[0], 'top'));
      expect(listB.rows[0].hasAttribute('data-drop-position')).toBe(false);

      await simulation.drop(listB.rows[0], towardsEdgeOf(listB.rows[0], 'top'));
      expect(transactions).toEqual([]);

      // Container space of the same list is gated too.
      const second = new NativeDragSimulation(listA.rows[1]);
      await second.start();
      listB.element.style.cssText = 'height:20px; padding-bottom:40px;';
      const listBRect = listB.element.getBoundingClientRect();
      const belowRows = { x: listBRect.left + listBRect.width / 2, y: listBRect.bottom - 5 };
      await second.drop(listB.element, belowRows);

      expect(transactions).toEqual([]);
    });

    it('accepts also gates same-list reorders (no same-list carve-out)', async () => {
      const { rows, intents } = setup(['a', 'b', 'c'], { accepts: () => false });
      const simulation = new NativeDragSimulation(rows[0]);

      await simulation.start();

      // Mid-drag: no indicator on the rejected list's own item target, even
      // though the drag originates from the very same list.
      await simulation.dragOver(rows[2], towardsEdgeOf(rows[2], 'bottom'));
      expect(rows[2].hasAttribute('data-drop-position')).toBe(false);

      await simulation.drop(rows[2], towardsEdgeOf(rows[2], 'bottom'));
      expect(intents).toEqual([]);
    });

    it('accepts gates a drop into an empty list', async () => {
      const { listA, listB, transactions } = setupTwoLists({ itemsB: [], acceptsB: () => false });
      const simulation = new NativeDragSimulation(listA.rows[0]);

      await simulation.start();

      listB.element.style.cssText = 'height:40px;';
      const listBRect = listB.element.getBoundingClientRect();
      const center = { x: listBRect.left + listBRect.width / 2, y: listBRect.top + listBRect.height / 2 };
      await simulation.drop(listB.element, center);

      expect(transactions).toEqual([]);
    });

    it('resolves a cross-list append into a populated list', async () => {
      const { listA, listB, transactions } = setupTwoLists();
      listB.element.style.cssText = 'height:20px; padding-bottom:40px;';
      const simulation = new NativeDragSimulation(listA.rows[0]);
      const listBRect = listB.element.getBoundingClientRect();
      const belowRows = { x: listBRect.left + listBRect.width / 2, y: listBRect.bottom - 5 };

      await simulation.start();
      await simulation.drop(listB.element, belowRows);

      expect(transactions).toHaveLength(1);
      expect(transactions[0].intent).toEqual({
        sourceId: 'a1',
        sourceListId: 'l1',
        targetListId: 'l2',
        targetItemId: null,
        edge: null,
        axis: 'vertical',
      });

      const transaction = transactions[0];
      transaction.complete(true);
      transaction.finalize();
      await transaction.completion;
    });

    it('resolves a cross-list append into an empty list', async () => {
      const { listA, listB, transactions } = setupTwoLists({ itemsB: [] });
      listB.element.style.cssText = 'height:40px;';
      const simulation = new NativeDragSimulation(listA.rows[0]);
      const listBRect = listB.element.getBoundingClientRect();
      const center = { x: listBRect.left + listBRect.width / 2, y: listBRect.top + listBRect.height / 2 };

      await simulation.start();
      await simulation.drop(listB.element, center);

      expect(transactions).toHaveLength(1);
      expect(transactions[0].intent).toEqual({
        sourceId: 'a1',
        sourceListId: 'l1',
        targetListId: 'l2',
        targetItemId: null,
        edge: null,
        axis: 'vertical',
      });

      const transaction = transactions[0];
      transaction.complete(true);
      transaction.finalize();
      await transaction.completion;
    });

    it('logs a diagnostic for an unsettled transaction after 10s', async () => {
      const warn = vi.spyOn(console, 'warn').mockImplementation(() => undefined);

      try {
        // Fake only the timer the diagnostic relies on: the drag simulation
        // still needs real animation frames to progress.
        vi.useFakeTimers({ toFake: ['setTimeout', 'clearTimeout'] });

        const { root, rows, transactions } = setup();
        const simulation = new NativeDragSimulation(rows[0]);
        await simulation.start();
        await simulation.drop(rows[2], towardsEdgeOf(rows[2], 'bottom'));

        const transaction = transactions[0];
        vi.advanceTimersByTime(10_000);

        expect(warn).toHaveBeenCalledWith(expect.stringContaining(transaction.id));
        expect(root.getAttribute('data-sortable-lists-busy')).toBe('true');
      } finally {
        vi.useRealTimers();
        warn.mockRestore();
      }
    });

    it('destroy cancels a pending unsettled-transaction diagnostic', async () => {
      const warn = vi.spyOn(console, 'warn').mockImplementation(() => undefined);

      try {
        // Fake only the timer the diagnostic relies on: the drag simulation
        // still needs real animation frames to progress.
        vi.useFakeTimers({ toFake: ['setTimeout', 'clearTimeout'] });

        const { rows, transactions, sortableRoot } = setup();
        const simulation = new NativeDragSimulation(rows[0]);
        await simulation.start();
        await simulation.drop(rows[2], towardsEdgeOf(rows[2], 'bottom'));

        const transaction = transactions[0];
        warn.mockClear(); // drop the unrelated "Auto scrolling..." registration noise

        // Never settled: destroy() must cancel its diagnostic timer instead
        // of leaving it to warn after the root is already torn down.
        sortableRoot.destroy();
        vi.advanceTimersByTime(10_000);

        expect(warn).not.toHaveBeenCalledWith(expect.stringContaining(transaction.id));
      } finally {
        vi.useRealTimers();
        warn.mockRestore();
      }
    });
  });

  describe('bounded stickiness (item→list handoff)', () => {
    it('sticky item target releases beyond the items span (vertical)', async () => {
      const { root, rows } = setup();
      root.style.cssText = 'padding-bottom:40px;';
      const simulation = new NativeDragSimulation(rows[0]);
      const lastRect = rows[2].getBoundingClientRect();
      const midSpanPoint = centerOf(rows[2]);

      await simulation.start();
      await simulation.dragOver(rows[2], midSpanPoint);
      expect(rows[2].hasAttribute('data-drop-position')).toBe(true);

      // Dispatched on the list element itself (a gap between rows), but the
      // coordinate is still within the items span: the item stays sticky.
      await simulation.dragOver(root, midSpanPoint);
      expect(rows[2].hasAttribute('data-drop-position')).toBe(true);
      expect(root.hasAttribute('data-drop-container')).toBe(false);

      // 30px past the last row, still inside the root's own padding: beyond
      // the span, so the list's container target takes over.
      const beyondSpan = { x: midSpanPoint.x, y: lastRect.bottom + 30 };
      await simulation.dragOver(root, beyondSpan);
      expect(rows[2].hasAttribute('data-drop-position')).toBe(false);
      expect(root.getAttribute('data-drop-container')).toBe('active');

      await simulation.cancel();
    });

    it('sticky handoff works horizontally', async () => {
      const { root, chips } = buildHorizontalList(['a', 'b', 'c']);
      root.style.cssText = 'white-space:nowrap; padding-right:40px;';
      const intents:SortableDropIntent[] = [];

      const sortableRoot = createSortableRoot({
        element: root,
        axis: 'horizontal',
        onDrop: (transaction) => intents.push(transaction.intent),
      });
      const listCleanup = sortableRoot.registerList({ element: root, listId: 'l1' });
      const itemCleanups = chips.map((chip, index) => sortableRoot.registerItem({
        element: chip,
        itemId: ['a', 'b', 'c'][index],
        listId: 'l1',
      }));
      cleanupFns.push(listCleanup, ...itemCleanups, () => sortableRoot.destroy());

      const simulation = new NativeDragSimulation(chips[0]);
      const lastRect = chips[2].getBoundingClientRect();
      const midSpanPoint = centerOf(chips[2]);

      await simulation.start();
      await simulation.dragOver(chips[2], midSpanPoint);
      expect(chips[2].hasAttribute('data-drop-position')).toBe(true);

      // Same handoff as the vertical case, along the horizontal axis.
      await simulation.dragOver(root, midSpanPoint);
      expect(chips[2].hasAttribute('data-drop-position')).toBe(true);
      expect(root.hasAttribute('data-drop-container')).toBe(false);

      const beyondSpan = { x: lastRect.right + 30, y: midSpanPoint.y };
      await simulation.dragOver(root, beyondSpan);
      expect(chips[2].hasAttribute('data-drop-position')).toBe(false);
      expect(root.getAttribute('data-drop-container')).toBe('active');

      await simulation.drop(root, beyondSpan);
      expect(intents).toEqual([{
        sourceId: 'a',
        sourceListId: 'l1',
        targetListId: 'l1',
        targetItemId: null,
        edge: null,
        axis: 'horizontal',
      }]);
    });

    it('handoff releases before the first item (leading edge)', async () => {
      const { root, rows } = setup();
      root.style.cssText = 'padding-top:40px;';
      const simulation = new NativeDragSimulation(rows[2]);
      const firstRect = rows[0].getBoundingClientRect();

      await simulation.start();

      // Above the first item, but still inside the root's own padding-top —
      // the leading edge of the items span.
      const aboveFirst = { x: centerOf(rows[0]).x, y: firstRect.top - 20 };
      await simulation.dragOver(root, aboveFirst);

      expect(rows[0].hasAttribute('data-drop-position')).toBe(false);
      expect(root.getAttribute('data-drop-container')).toBe('active');

      await simulation.cancel();
    });

    it('wrap-aware: releases stickiness for blank space beyond the union rect of wrapped rows', async () => {
      // Container fits exactly two 40px chips per row (44px with margin), so
      // 'a'/'b' occupy row one and 'c' wraps onto row two.
      const { root, chips } = buildWrappingHorizontalList(['a', 'b', 'c'], 92);
      const intents:SortableDropIntent[] = [];

      const sortableRoot = createSortableRoot({
        element: root,
        axis: 'horizontal',
        onDrop: (transaction) => intents.push(transaction.intent),
      });
      const listCleanup = sortableRoot.registerList({ element: root, listId: 'l1' });
      const itemCleanups = chips.map((chip, index) => sortableRoot.registerItem({
        element: chip,
        itemId: ['a', 'b', 'c'][index],
        listId: 'l1',
      }));
      cleanupFns.push(listCleanup, ...itemCleanups, () => sortableRoot.destroy());

      const firstRowRect = chips[0].getBoundingClientRect();
      const secondRowRect = chips[2].getBoundingClientRect();
      expect(secondRowRect.top).toBeGreaterThan(firstRowRect.top); // sanity: actually wrapped

      const simulation = new NativeDragSimulation(chips[0]);
      await simulation.start();

      await simulation.dragOver(chips[2], centerOf(chips[2]));
      expect(chips[2].hasAttribute('data-drop-position')).toBe(true);

      // Below the wrapped rows, in the container's trailing blank space. The
      // X coordinate still falls in the first row's extent, so a root-axis-
      // only bound would falsely keep the second row's chip sticky here.
      const beyondUnion = { x: centerOf(chips[0]).x, y: secondRowRect.bottom + 30 };
      await simulation.dragOver(root, beyondUnion);
      expect(chips[2].hasAttribute('data-drop-position')).toBe(false);
      expect(root.getAttribute('data-drop-container')).toBe('active');

      await simulation.drop(root, beyondUnion);
      expect(intents).toEqual([{
        sourceId: 'a',
        sourceListId: 'l1',
        targetListId: 'l1',
        targetItemId: null,
        edge: null,
        axis: 'horizontal',
      }]);
    });

    describe('card grid geometry', () => {
      // 3 columns, 5 cards: 'a'/'b'/'c' fill row one, 'd'/'e' leave the third
      // track of row two empty.
      function setupGrid(items = ['a', 'b', 'c', 'd', 'e']) {
        const { root, cards } = buildCardGrid(items, 3);
        const intents:SortableDropIntent[] = [];
        const sortableRoot = createSortableRoot({
          element: root,
          axis: 'horizontal',
          onDrop: (transaction) => { intents.push(transaction.intent); transaction.complete(true); },
        });
        const listCleanup = sortableRoot.registerList({ element: root, listId: 'l1' });
        const itemCleanups = cards.map((card, index) => sortableRoot.registerItem({
          element: card,
          itemId: items[index],
          listId: 'l1',
        }));
        cleanupFns.push(listCleanup, ...itemCleanups, () => sortableRoot.destroy());

        return { root, cards, intents };
      }

      it('appends on a drop in the empty trailing track of an incomplete row', async () => {
        const { root, cards, intents } = setupGrid();
        const simulation = new NativeDragSimulation(cards[0]);

        await simulation.start();
        await simulation.dragOver(cards[4], centerOf(cards[4]));
        expect(cards[4].hasAttribute('data-drop-position')).toBe(true);

        // Row two's third track: no card in it, but it sits inside the union
        // of every card rect, which is what used to keep 'e' sticky here.
        const emptyTrack = { x: centerOf(cards[2]).x, y: centerOf(cards[4]).y };
        await simulation.dragOver(root, emptyTrack);

        expect(cards[4].hasAttribute('data-drop-position')).toBe(false);
        expect(root.getAttribute('data-drop-container')).toBe('active');

        await simulation.drop(root, emptyTrack);

        expect(intents).toEqual([{
          sourceId: 'a',
          sourceListId: 'l1',
          targetListId: 'l1',
          targetItemId: null,
          edge: null,
          axis: 'horizontal',
        }]);
      });

      it('keeps the item sticky in the gap between two rows', async () => {
        const { root, cards } = setupGrid();
        const simulation = new NativeDragSimulation(cards[0]);
        const gap = {
          x: centerOf(cards[3]).x,
          y: (cards[0].getBoundingClientRect().bottom + cards[3].getBoundingClientRect().top) / 2,
        };

        await simulation.start();
        await simulation.dragOver(cards[3], centerOf(cards[3]));
        expect(cards[3].hasAttribute('data-drop-position')).toBe(true);

        await simulation.dragOver(root, gap);

        expect(cards[3].hasAttribute('data-drop-position')).toBe(true);
        expect(root.hasAttribute('data-drop-container')).toBe(false);

        await simulation.cancel();
      });

      it('ignores a hidden card rather than stretching the span to the viewport origin', async () => {
        const { root, cards } = setupGrid();
        cards[4].style.display = 'none';
        const simulation = new NativeDragSimulation(cards[0]);

        await simulation.start();
        await simulation.dragOver(cards[3], centerOf(cards[3]));
        expect(cards[3].hasAttribute('data-drop-position')).toBe(true);

        // Inside the list's own leading padding, left of every card. A 0×0
        // rect at the viewport origin would pull the span's left edge to 0 and
        // hold the item sticky here.
        const leftOfCards = { x: root.getBoundingClientRect().left + 20, y: centerOf(cards[3]).y };
        expect(leftOfCards.x).toBeLessThan(cards[3].getBoundingClientRect().left);
        await simulation.dragOver(root, leftOfCards);

        expect(cards[3].hasAttribute('data-drop-position')).toBe(false);
        expect(root.getAttribute('data-drop-container')).toBe('active');

        await simulation.cancel();
      });

      it('has no span at all when every registered card is hidden', async () => {
        const { root, cards } = setupGrid();
        const simulation = new NativeDragSimulation(cards[0]);
        const point = centerOf(cards[3]);

        await simulation.start();
        await simulation.dragOver(cards[3], point);
        expect(cards[3].hasAttribute('data-drop-position')).toBe(true);

        cards.forEach((card) => { card.style.display = 'none'; });
        await simulation.dragOver(root, point);

        expect(cards[3].hasAttribute('data-drop-position')).toBe(false);
        expect(root.getAttribute('data-drop-container')).toBe('active');

        await simulation.cancel();
      });
    });

    it('crossing a row boundary resolves a left/right edge on the target chip', async () => {
      // Container fits exactly two 40px chips per row (44px with margin), so
      // 'a'/'b' occupy row one and 'c' wraps onto row two.
      const { root, chips } = buildWrappingHorizontalList(['a', 'b', 'c'], 92);
      const intents:SortableDropIntent[] = [];

      const sortableRoot = createSortableRoot({
        element: root,
        axis: 'horizontal',
        onDrop: (transaction) => intents.push(transaction.intent),
      });
      const listCleanup = sortableRoot.registerList({ element: root, listId: 'l1' });
      const itemCleanups = chips.map((chip, index) => sortableRoot.registerItem({
        element: chip,
        itemId: ['a', 'b', 'c'][index],
        listId: 'l1',
      }));
      cleanupFns.push(listCleanup, ...itemCleanups, () => sortableRoot.destroy());

      // Dragging row-two's only chip onto row-one's second chip: the closest
      // edge is still resolved along the horizontal (row-local) axis, not the
      // vertical row boundary the two chips actually straddle.
      const simulation = new NativeDragSimulation(chips[2]);
      await simulation.start();
      await simulation.drop(chips[1], towardsEdgeOf(chips[1], 'right'));

      expect(intents[0]).toMatchObject({ targetItemId: 'b', edge: 'right', axis: 'horizontal' });
    });

    it('resolves left at the first chip and right at the last chip at their quarter points', async () => {
      const { root, chips } = buildWrappingHorizontalList(['a', 'b', 'c'], 92);
      const intents:SortableDropIntent[] = [];

      const sortableRoot = createSortableRoot({
        element: root,
        axis: 'horizontal',
        onDrop: (transaction) => { intents.push(transaction.intent); transaction.complete(true); },
      });
      const listCleanup = sortableRoot.registerList({ element: root, listId: 'l1' });
      const itemCleanups = chips.map((chip, index) => sortableRoot.registerItem({
        element: chip,
        itemId: ['a', 'b', 'c'][index],
        listId: 'l1',
      }));
      cleanupFns.push(listCleanup, ...itemCleanups, () => sortableRoot.destroy());

      const first = new NativeDragSimulation(chips[2]);
      await first.start();
      await first.drop(chips[0], towardsEdgeOf(chips[0], 'left'));
      expect(intents[0]).toMatchObject({ targetItemId: 'a', edge: 'left' });

      const second = new NativeDragSimulation(chips[0]);
      await second.start();
      await second.drop(chips[2], towardsEdgeOf(chips[2], 'right'));
      expect(intents[1]).toMatchObject({ targetItemId: 'c', edge: 'right' });
    });

    it('resolves a container append for the trailing blank space of a wrapped list', async () => {
      const { root, chips } = buildWrappingHorizontalList(['a', 'b', 'c'], 92);
      const intents:SortableDropIntent[] = [];

      const sortableRoot = createSortableRoot({
        element: root,
        axis: 'horizontal',
        onDrop: (transaction) => intents.push(transaction.intent),
      });
      const listCleanup = sortableRoot.registerList({ element: root, listId: 'l1' });
      const itemCleanups = chips.map((chip, index) => sortableRoot.registerItem({
        element: chip,
        itemId: ['a', 'b', 'c'][index],
        listId: 'l1',
      }));
      cleanupFns.push(listCleanup, ...itemCleanups, () => sortableRoot.destroy());

      const lastRowRect = chips[2].getBoundingClientRect();
      const belowUnion = { x: centerOf(chips[0]).x, y: lastRowRect.bottom + 30 };

      const simulation = new NativeDragSimulation(chips[0]);
      await simulation.start();
      await simulation.drop(root, belowUnion);

      expect(intents).toEqual([{
        sourceId: 'a',
        sourceListId: 'l1',
        targetListId: 'l1',
        targetItemId: null,
        edge: null,
        axis: 'horizontal',
      }]);
    });
  });

  describe('drag-start gating', () => {
    it('drag does not start from an interactive descendant', async () => {
      const { rows } = setup(['a']);
      const button = document.createElement('button');
      button.type = 'button';
      button.textContent = 'Actions';
      button.style.cssText = 'display:block; width:16px; height:16px;';
      rows[0].appendChild(button);

      const simulation = new NativeDragSimulation(rows[0]);
      await simulation.start(centerOf(button));

      expect(rows[0].hasAttribute('data-dragging')).toBe(false);
    });

    it('consumer canDrag gate composes', async () => {
      const { root, rows } = buildList(['a', 'b']);
      const sortableRoot = createSortableRoot({ element: root, onDrop: () => undefined });
      const listCleanup = sortableRoot.registerList({ element: root, listId: 'l1' });
      const itemCleanupA = sortableRoot.registerItem({
        element: rows[0], itemId: 'a', listId: 'l1', canDrag: () => false,
      });
      const itemCleanupB = sortableRoot.registerItem({ element: rows[1], itemId: 'b', listId: 'l1' });
      cleanupFns.push(listCleanup, itemCleanupA, itemCleanupB, () => sortableRoot.destroy());

      const blocked = new NativeDragSimulation(rows[0]);
      await blocked.start();
      expect(rows[0].hasAttribute('data-dragging')).toBe(false);

      const allowed = new NativeDragSimulation(rows[1]);
      await allowed.start();
      expect(rows[1].dataset.dragging).toBe('source');

      await allowed.cancel();
    });

    it('drag starts from an activation surface opting in via data-draggable-surface', async () => {
      const { rows } = setup(['a']);
      const surface = document.createElement('div');
      surface.setAttribute('role', 'button');
      surface.tabIndex = 0;
      surface.setAttribute('data-draggable-surface', '');
      surface.style.cssText = 'display:block; height:20px;';
      surface.textContent = 'card body';
      rows[0].appendChild(surface);

      const simulation = new NativeDragSimulation(rows[0]);
      await simulation.start(centerOf(surface));

      expect(rows[0].dataset.dragging).toBe('source');
      await simulation.cancel();
    });

    it('a button nested inside an exempt activation surface still blocks drag start', async () => {
      const { rows } = setup(['a']);
      const surface = document.createElement('div');
      surface.setAttribute('role', 'button');
      surface.tabIndex = 0;
      surface.setAttribute('data-draggable-surface', '');
      surface.style.cssText = 'display:block;';
      const button = document.createElement('button');
      button.type = 'button';
      button.textContent = 'Details';
      button.style.cssText = 'display:block; width:16px; height:16px;';
      surface.appendChild(button);
      rows[0].appendChild(surface);

      const simulation = new NativeDragSimulation(rows[0]);
      await simulation.start(centerOf(button));

      expect(rows[0].hasAttribute('data-dragging')).toBe(false);
    });
  });

  describe('autoscroll registration dedupe', () => {
    it('keeps a shared scroll container registered until the last holder releases', () => {
      const { root } = buildList(['a']);
      const scroller = document.createElement('div');
      scroller.style.cssText = 'overflow-y:auto; height:100px;';
      document.body.appendChild(scroller);

      const sortableRoot = createSortableRoot({ element: root, onDrop: () => undefined });
      cleanupFns.push(() => sortableRoot.destroy());
      const listCleanup = sortableRoot.registerList({ element: root, listId: 'l1', scrollContainer: scroller });
      const extraCleanup = sortableRoot.addScrollContainer(scroller);

      expect(liveRegistrations()).toHaveLength(1);

      // Pragmatic's registry is keyed by element; without refcounting, the
      // first release would delete the survivor's registration with it.
      listCleanup();
      expect(liveRegistrations()).toHaveLength(1);

      extraCleanup();
      expect(liveRegistrations()).toHaveLength(0);
    });

    it('unions axes across acquisitions and keeps one live registration', () => {
      const { root } = buildList(['a']);
      const scroller = document.createElement('div');
      scroller.style.cssText = 'overflow-y:auto; height:100px;';
      document.body.appendChild(scroller);

      const sortableRoot = createSortableRoot({ element: root, onDrop: () => undefined });
      cleanupFns.push(() => sortableRoot.destroy());
      const listCleanup = sortableRoot.registerList({ element: root, listId: 'l1', scrollContainer: scroller });
      const extraCleanup = sortableRoot.addScrollContainer(scroller, 'horizontal');

      // vertical (registerList default) + horizontal => union 'all'
      expect(liveRegistrations()).toHaveLength(1);
      expect(liveRegistrations()[0].getAllowedAxis()).toBe('all');

      listCleanup(); // release in acquisition order: registration survives
      expect(liveRegistrations()).toHaveLength(1);
      extraCleanup();
      expect(liveRegistrations()).toHaveLength(0);
    });

    it('reverse release order and destroy-after-partial-release both clean up fully', () => {
      const { root } = buildList(['a']);
      const scroller = document.createElement('div');
      scroller.style.cssText = 'overflow-y:auto; height:100px;';
      document.body.appendChild(scroller);

      const sortableRoot = createSortableRoot({ element: root, onDrop: () => undefined });
      const listCleanup = sortableRoot.registerList({ element: root, listId: 'l1', scrollContainer: scroller });
      const extraCleanup = sortableRoot.addScrollContainer(scroller);

      extraCleanup(); // reverse order first
      expect(liveRegistrations()).toHaveLength(1);

      sortableRoot.destroy(); // destroy while listCleanup is still held
      expect(liveRegistrations()).toHaveLength(0);
      listCleanup(); // idempotent afterwards — must not throw
    });

    it('autoScrollAxis overrides the placement axis for list scroll containers', () => {
      const { root } = buildList(['a']);
      const scroller = document.createElement('div');
      scroller.style.cssText = 'overflow-y:auto; height:100px;';
      document.body.appendChild(scroller);

      const sortableRoot = createSortableRoot({
        element: root, axis: 'horizontal', autoScrollAxis: 'all', onDrop: () => undefined,
      });
      cleanupFns.push(() => sortableRoot.destroy());
      sortableRoot.registerList({ element: root, listId: 'l1', scrollContainer: scroller });

      expect(liveRegistrations()[0].getAllowedAxis()).toBe('all');
    });
  });

  describe('drop intent axis', () => {
    it('drop intents carry the root placement axis', async () => {
      const { root, chips } = buildHorizontalList(['a', 'b']);
      const intents:SortableDropIntent[] = [];
      const sortableRoot = createSortableRoot({
        element: root, axis: 'horizontal', onDrop: (t) => { intents.push(t.intent); t.complete(true); },
      });
      cleanupFns.push(() => sortableRoot.destroy());
      sortableRoot.registerList({ element: root, listId: 'l1' });
      sortableRoot.registerItem({ element: chips[0], itemId: 'a', listId: 'l1' });
      sortableRoot.registerItem({ element: chips[1], itemId: 'b', listId: 'l1' });

      const simulation = new NativeDragSimulation(chips[0]);
      await simulation.start();
      await simulation.drop(chips[1], towardsEdgeOf(chips[1], 'right'));

      expect(intents[0].axis).toBe('horizontal');
    });
  });

  describe('custom preview factory', () => {
    it('custom preview factory renders and cleans up', async () => {
      const cleanup = vi.fn();
      const calls:{ source:SortableSource; container:HTMLElement }[] = [];
      let previewPresentAtDragStart = false;

      const { root, rows } = buildList(['a', 'b']);
      const sortableRoot = createSortableRoot({
        element: root,
        preview: ({ source, container }) => {
          calls.push({ source, container });
          container.append(Object.assign(document.createElement('div'), {
            className: 'test-preview',
            textContent: source.itemId,
          }));
          return cleanup;
        },
        onDragStarted: () => {
          // The preview is still mounted at this exact synchronous point —
          // the only observable window before Pragmatic tears it down.
          previewPresentAtDragStart = document.querySelector('.test-preview') !== null;
        },
        onDrop: () => undefined,
      });
      const listCleanup = sortableRoot.registerList({ element: root, listId: 'l1' });
      const itemCleanups = rows.map((row, index) => sortableRoot.registerItem({
        element: row,
        itemId: ['a', 'b'][index],
        listId: 'l1',
      }));
      cleanupFns.push(listCleanup, ...itemCleanups, () => sortableRoot.destroy());

      const simulation = new NativeDragSimulation(rows[0]);
      await simulation.start();

      expect(calls).toHaveLength(1);
      expect(calls[0].source).toMatchObject({ itemId: 'a', listId: 'l1' });
      expect(calls[0].container).toBeInstanceOf(HTMLElement);
      expect(previewPresentAtDragStart).toBe(true);

      await simulation.drop(rows[1], towardsEdgeOf(rows[1], 'bottom'));

      expect(cleanup).toHaveBeenCalledTimes(1);
    });
  });
});

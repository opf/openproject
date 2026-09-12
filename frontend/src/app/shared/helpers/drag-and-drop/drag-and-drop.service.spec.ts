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

import { TestBed } from '@angular/core/testing';
import {
  afterEach, beforeEach, describe, expect, it, vi,
} from 'vitest';
import {
  NativeDragSimulation,
  centerOf,
  towardsEdgeOf,
} from 'core-common/drag-and-drop/testing/native-drag-simulation';
import { DragAndDropService, type DragMember } from './drag-and-drop.service';

// Table-like fixture: a container standing in for `tbody`, with direct-child
// rows carrying `data-work-package-id` (the service's `ROW_SELECTOR`) and an
// optional handle span sized to only part of the row, so a drag started
// elsewhere on the row still resolves `elementFromPoint` to the row itself
// (no handle class) rather than to nothing.
function buildRow(id:string, opts:{ handle?:boolean } = {}):HTMLElement {
  const row = document.createElement('div');
  row.dataset.workPackageId = id;
  row.style.cssText = 'position:relative; height:20px; width:200px;';
  row.textContent = id;

  if (opts.handle) {
    const handle = document.createElement('span');
    handle.className = 'wp-table--drag-and-drop-handle';
    handle.style.cssText = 'position:absolute; left:0; top:0; width:20px; height:20px;';
    row.appendChild(handle);
  }

  return row;
}

function buildContainer(ids:string[], opts:{ handle?:boolean } = {}):{ container:HTMLElement; rows:HTMLElement[] } {
  const container = document.createElement('div');
  // `overflow-y` with no height keeps the container a scroll container for
  // Pragmatic's computed-overflow check. This also computes overflow-x to
  // `auto`, but rows are exactly 200px wide in a 200px container.
  container.style.cssText = 'width:200px; overflow-y:auto;';
  const rows = ids.map((id) => {
    const row = buildRow(id, opts);
    container.appendChild(row);
    return row;
  });
  document.body.appendChild(container);

  return { container, rows };
}

// `onMoved` is mandatory on `DragMember`, and every test that cares about it
// wants its own handle to assert against — reading it back off `member`
// would hit `@typescript-eslint/unbound-method` (the interface declares its
// callbacks with method-shorthand syntax), so callers always pass their own
// spy and keep the local reference for assertions instead.
function buildMember(container:HTMLElement, overrides:Partial<DragMember> & Pick<DragMember, 'onMoved'>):DragMember {
  return {
    dragContainer: container,
    scrollContainers: [],
    itemIdOf: (row) => row.dataset.workPackageId ?? null,
    canPickup: () => true,
    accepts: () => true,
    ...overrides,
  };
}

// The service's row registration runs synchronously on `register()`, but
// subsequent DOM mutations are picked up through a `MutationObserver`, whose
// callback is scheduled as a microtask rather than running inline with the
// mutation. Two microtask hops are enough to flush it under the real
// (chromium) drag simulation used throughout this suite.
async function settle():Promise<void> {
  await new Promise<void>((resolve) => { queueMicrotask(resolve); });
  await new Promise<void>((resolve) => { queueMicrotask(resolve); });
}

function isBusy(container:HTMLElement):boolean {
  return container.getAttribute('data-sortable-lists-busy') === 'true';
}

describe('DragAndDropService', () => {
  let service:DragAndDropService;

  beforeEach(() => {
    TestBed.configureTestingModule({ providers: [DragAndDropService] });
    service = TestBed.inject(DragAndDropService);
  });

  afterEach(() => {
    service.ngOnDestroy();
    document.body.replaceChildren();
  });

  describe('within-list reorder', () => {
    it('reports a bottom-edge drop as an intent with the target row and edge', async () => {
      const { container, rows } = buildContainer(['a0', 'a1', 'a2']);
      const onMoved = vi.fn();
      service.register(buildMember(container, { onMoved }));

      const simulation = new NativeDragSimulation(rows[0]);
      await simulation.start();
      await simulation.drop(rows[2], towardsEdgeOf(rows[2], 'bottom'));

      expect(onMoved).toHaveBeenCalledWith(
        { sourceId: 'a0', targetId: 'a2', edge: 'bottom' },
        expect.any(Function),
      );

      const complete = onMoved.mock.calls[0][1] as (success:boolean) => void;
      complete(true);
      await settle();
      expect(isBusy(container)).toBe(false);
    });

    it('reports a top-edge drop as an intent with the target row and edge', async () => {
      const { container, rows } = buildContainer(['a0', 'a1', 'a2']);
      const onMoved = vi.fn();
      service.register(buildMember(container, { onMoved }));

      const simulation = new NativeDragSimulation(rows[2]);
      await simulation.start();
      await simulation.drop(rows[1], towardsEdgeOf(rows[1], 'top'));

      expect(onMoved).toHaveBeenCalledWith(
        { sourceId: 'a2', targetId: 'a1', edge: 'top' },
        expect.any(Function),
      );

      const complete = onMoved.mock.calls[0][1] as (success:boolean) => void;
      complete(true);
      await settle();
      expect(isBusy(container)).toBe(false);
    });
  });

  describe('container append', () => {
    it('reports a drop below the rows as a null-target append intent', async () => {
      const { container, rows } = buildContainer(['a0', 'a1']);
      container.style.cssText = 'width:200px; padding-bottom:40px; overflow-y:auto;';
      const onMoved = vi.fn();
      service.register(buildMember(container, { onMoved }));

      const simulation = new NativeDragSimulation(rows[0]);
      const containerRect = container.getBoundingClientRect();
      const belowRows = { x: containerRect.left + containerRect.width / 2, y: containerRect.bottom - 5 };

      await simulation.start();
      await simulation.drop(container, belowRows);

      expect(onMoved).toHaveBeenCalledWith(
        { sourceId: 'a0', targetId: null, edge: null },
        expect.any(Function),
      );
    });
  });

  describe('no-op drop', () => {
    it('drop-on-self settles without calling onMoved', async () => {
      const { container, rows } = buildContainer(['a0', 'a1']);
      const onMoved = vi.fn();
      service.register(buildMember(container, { onMoved }));

      const simulation = new NativeDragSimulation(rows[0]);
      await simulation.start();
      await simulation.drop(rows[0], centerOf(rows[0]));

      expect(onMoved).not.toHaveBeenCalled();
      expect(isBusy(container)).toBe(false);
    });

    it('a drop that resolves to the same order settles without calling onMoved', async () => {
      // a1 dropped on a0's bottom edge is already exactly where it sits.
      const { container, rows } = buildContainer(['a0', 'a1', 'a2']);
      const onMoved = vi.fn();
      service.register(buildMember(container, { onMoved }));

      const simulation = new NativeDragSimulation(rows[1]);
      await simulation.start();
      await simulation.drop(rows[0], towardsEdgeOf(rows[0], 'bottom'));

      expect(onMoved).not.toHaveBeenCalled();
      expect(isBusy(container)).toBe(false);
    });
  });

  describe('handle gating', () => {
    it('does not start a drag from a non-handle point on the row', async () => {
      const { container, rows } = buildContainer(['a0'], { handle: true });
      service.register(buildMember(container, {
        onMoved: vi.fn(),
        canPickup: (row, handle) => handle?.classList.contains('wp-table--drag-and-drop-handle') ?? false,
      }));

      const simulation = new NativeDragSimulation(rows[0]);
      // Away from the 20x20 handle sitting in the row's top-left corner.
      await simulation.start({ x: 150, y: rows[0].getBoundingClientRect().top + 10 });

      expect(rows[0].hasAttribute('data-dragging')).toBe(false);
    });

    it('starts a drag from the handle', async () => {
      const { container, rows } = buildContainer(['a0'], { handle: true });
      const handle = rows[0].querySelector<HTMLElement>('.wp-table--drag-and-drop-handle')!;
      service.register(buildMember(container, {
        onMoved: vi.fn(),
        canPickup: (row, h) => h?.classList.contains('wp-table--drag-and-drop-handle') ?? false,
      }));

      const simulation = new NativeDragSimulation(rows[0]);
      await simulation.start(centerOf(handle));

      expect(rows[0].dataset.dragging).toBe('source');
      await simulation.cancel();
    });
  });

  describe('canPickup', () => {
    it('blocks the drag when canPickup returns false', async () => {
      const { container, rows } = buildContainer(['a0']);
      const onDragStarted = vi.fn();
      service.register(buildMember(container, { onMoved: vi.fn(), canPickup: () => false, onDragStarted }));

      const simulation = new NativeDragSimulation(rows[0]);
      await simulation.start();

      expect(rows[0].hasAttribute('data-dragging')).toBe(false);
      expect(onDragStarted).not.toHaveBeenCalled();
    });
  });

  describe('accepts', () => {
    it('blocks the container\'s own reorder when accepts returns false (no same-list carve-out)', async () => {
      const { container, rows } = buildContainer(['a0', 'a1', 'a2']);
      const onMoved = vi.fn();
      service.register(buildMember(container, { onMoved, accepts: () => false }));

      const simulation = new NativeDragSimulation(rows[0]);
      await simulation.start();
      await simulation.drop(rows[2], towardsEdgeOf(rows[2], 'bottom'));

      expect(onMoved).not.toHaveBeenCalled();
      expect(isBusy(container)).toBe(false);
    });
  });

  describe('MutationObserver re-registration', () => {
    it('registers a row appended after register() and allows dragging it', async () => {
      const { container, rows } = buildContainer(['a0', 'a1']);
      const onMoved = vi.fn();
      service.register(buildMember(container, { onMoved }));

      const late = buildRow('a2');
      container.appendChild(late);
      await settle();

      const simulation = new NativeDragSimulation(late);
      await simulation.start();
      await simulation.drop(rows[0], towardsEdgeOf(rows[0], 'top'));

      expect(onMoved).toHaveBeenCalledWith(
        { sourceId: 'a2', targetId: 'a0', edge: 'top' },
        expect.any(Function),
      );
    });

    it('releases a row removed from the DOM so dragging it is inert', async () => {
      const { container, rows } = buildContainer(['a0', 'a1']);
      const onDragStarted = vi.fn();
      service.register(buildMember(container, { onMoved: vi.fn(), onDragStarted }));

      container.removeChild(rows[0]);
      await settle();

      const simulation = new NativeDragSimulation(rows[0]);
      await simulation.start();

      expect(rows[0].hasAttribute('data-dragging')).toBe(false);
      expect(onDragStarted).not.toHaveBeenCalled();
    });
  });

  describe('preview factory', () => {
    it('invokes renderPreview synchronously with the chrome class already present', async () => {
      const { container, rows } = buildContainer(['a0', 'a1']);
      const renderPreview = vi.fn();
      let previewAtDragStart:Element|null = null;

      service.register(buildMember(container, {
        onMoved: vi.fn(),
        renderPreview,
        onDragStarted: vi.fn(() => {
          // The only observable window before Pragmatic tears the preview
          // down again — mirrors the engine spec's own preview test.
          previewAtDragStart = document.querySelector('.op-drag-preview');
        }),
      }));

      const simulation = new NativeDragSimulation(rows[0]);
      await simulation.start();

      expect(renderPreview).toHaveBeenCalledTimes(1);
      const [previewRow, preview] = renderPreview.mock.calls[0] as [HTMLElement, HTMLElement];
      expect(previewRow).toBe(rows[0]);
      expect(preview.classList.contains('op-drag-preview')).toBe(true);
      expect(previewAtDragStart).toBe(preview);

      // Never Pragmatic's own container: its popover reset is inline, so
      // any chrome placed there is dead on arrival.
      expect(preview.parentElement?.style.position).toBe('fixed');

      await simulation.cancel();
    });

    it('leaves the preview container empty for renderPreview, without cloning the row', async () => {
      const { container, rows } = buildContainer(['a0', 'a1']);
      let childrenAtDragStart:string[] = [];

      service.register(buildMember(container, {
        onMoved: vi.fn(),
        // A hook that renders nothing still means "no clone": the row's own
        // markup must never reach the preview behind the consumer's back.
        renderPreview: () => undefined,
        onDragStarted: vi.fn(() => {
          const preview = document.querySelector('.op-drag-preview');
          childrenAtDragStart = Array.from(preview?.children ?? []).map((child) => child.outerHTML);
        }),
      }));

      const simulation = new NativeDragSimulation(rows[0]);
      await simulation.start();

      expect(childrenAtDragStart).toEqual([]);

      await simulation.cancel();
    });

    it('clones the source row when no renderPreview is supplied', async () => {
      const { container, rows } = buildContainer(['a0', 'a1']);
      let clonedIdAtDragStart:string|undefined;

      service.register(buildMember(container, {
        onMoved: vi.fn(),
        onDragStarted: vi.fn(() => {
          const clone = document.querySelector('.op-drag-preview')?.firstElementChild as HTMLElement|undefined;
          clonedIdAtDragStart = clone?.dataset.workPackageId;
        }),
      }));

      const simulation = new NativeDragSimulation(rows[0]);
      await simulation.start();

      expect(clonedIdAtDragStart).toBe('a0');

      await simulation.cancel();
    });
  });

  describe('onCancel', () => {
    it('fires onCancel with the source row when dropped outside every registered container', async () => {
      const { container, rows } = buildContainer(['a0', 'a1']);
      const onCancel = vi.fn();
      const onMoved = vi.fn();
      service.register(buildMember(container, { onMoved, onCancel }));

      const outside = document.createElement('div');
      outside.style.cssText = 'position:fixed; top:500px; left:500px; width:50px; height:50px;';
      document.body.appendChild(outside);

      const simulation = new NativeDragSimulation(rows[0]);
      await simulation.start();
      await simulation.drop(outside, centerOf(outside));

      expect(onCancel).toHaveBeenCalledWith(rows[0]);
      expect(onMoved).not.toHaveBeenCalled();
      expect(rows[0].hasAttribute('data-dragging')).toBe(false);
    });
  });

  describe('busy serialization', () => {
    it('rejects a second drag while a transaction is pending, then allows one after completion', async () => {
      const { container, rows } = buildContainer(['a0', 'a1', 'a2']);
      const onMoved = vi.fn();
      service.register(buildMember(container, { onMoved }));

      const first = new NativeDragSimulation(rows[0]);
      await first.start();
      await first.drop(rows[2], towardsEdgeOf(rows[2], 'bottom'));

      expect(onMoved).toHaveBeenCalledTimes(1);
      expect(isBusy(container)).toBe(true);
      const complete = onMoved.mock.calls[0][1] as (success:boolean) => void;

      // A second drag attempt while the first transaction is still pending
      // never even starts (canDrag is gated on the root's busy attribute).
      const second = new NativeDragSimulation(rows[1]);
      await second.start();
      expect(rows[1].hasAttribute('data-dragging')).toBe(false);
      await second.drop(rows[2], towardsEdgeOf(rows[2], 'bottom'));
      expect(onMoved).toHaveBeenCalledTimes(1);
      expect(isBusy(container)).toBe(true);

      complete(true);
      await settle();
      expect(isBusy(container)).toBe(false);

      const third = new NativeDragSimulation(rows[1]);
      await third.start();
      await third.drop(rows[2], towardsEdgeOf(rows[2], 'bottom'));
      expect(onMoved).toHaveBeenCalledTimes(2);
    });
  });

  describe('remove()', () => {
    it('tears down registration so a subsequent drag is inert', async () => {
      const { container, rows } = buildContainer(['a0', 'a1']);
      const onDragStarted = vi.fn();
      const onMoved = vi.fn();
      service.register(buildMember(container, { onMoved, onDragStarted }));

      service.remove(container);

      const simulation = new NativeDragSimulation(rows[0]);
      await simulation.start();

      expect(rows[0].hasAttribute('data-dragging')).toBe(false);
      expect(onDragStarted).not.toHaveBeenCalled();
      expect(onMoved).not.toHaveBeenCalled();
    });
  });
});

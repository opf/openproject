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
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { Component, signal } from '@angular/core';
import { ComponentFixture, TestBed } from '@angular/core/testing';
import {
  NativeDragSimulation,
  centerOf,
  towardsEdgeOf,
} from 'core-common/drag-and-drop/testing/native-drag-simulation';
import { OpSortableListsItemDirective } from './sortable-lists-item.directive';
import { OpSortableListsDirective, SortableListsDropEvent } from './sortable-lists.directive';

// Two lists with overlapping item ids: the second list proves per-instance
// isolation, since only the payload scope distinguishes their items. Neither
// declares an `opSortableListsList` child, so both operate in collapse mode.
@Component({
  imports: [OpSortableListsDirective, OpSortableListsItemDirective],
  template: `
    <div
      class="list-one"
      opSortableLists
      (opSortableListsDrop)="drops.push($event)"
      style="overflow: auto;"
    >
      @for (id of ids(); track id) {
        <div class="item" [opSortableListsItem]="id" style="height: 40px; width: 200px;">
          <span>{{ id }}</span>
          <button type="button" class="remove-button" style="width: 30px; height: 20px;">x</button>
        </div>
      }
    </div>

    <div
      class="list-two"
      opSortableLists
      (opSortableListsDrop)="otherDrops.push($event)"
      style="overflow: auto;"
    >
      @for (id of otherIds(); track id) {
        <div class="item" [opSortableListsItem]="id" style="height: 40px; width: 200px;">{{ id }}</div>
      }
    </div>
  `,
})
class TestHostComponent {
  ids = signal(['a', 'b', 'c']);
  otherIds = signal(['a', 'b', 'c']);
  drops:SortableListsDropEvent[] = [];
  otherDrops:SortableListsDropEvent[] = [];
}

// Ignores the transaction bookkeeping fields; only the resolved intent matters here.
function intents(events:SortableListsDropEvent[]) {
  return events.map(({ sourceId, targetId, edge }) => ({ sourceId, targetId, edge }));
}

describe('sortable-lists directives', () => {
  let fixture:ComponentFixture<TestHostComponent>;
  let host:TestHostComponent;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [TestHostComponent],
    }).compileComponents();

    fixture = TestBed.createComponent(TestHostComponent);
    host = fixture.componentInstance;
    fixture.detectChanges();
  });

  function item(list:string, index:number):HTMLElement {
    const items = (fixture.nativeElement as HTMLElement).querySelectorAll<HTMLElement>(`.${list} .item`);
    return items[index];
  }

  it('emits the source id, target id and closest edge on drop', async () => {
    const simulation = new NativeDragSimulation(item('list-one', 0));

    await simulation.start();
    await simulation.drop(item('list-one', 2), towardsEdgeOf(item('list-one', 2), 'bottom'));

    expect(intents(host.drops)).toEqual([{ sourceId: 'a', targetId: 'c', edge: 'bottom' }]);
  });

  it('reflects drag and drop-position state through host attributes', async () => {
    const source = item('list-one', 0);
    const target = item('list-one', 2);
    const simulation = new NativeDragSimulation(source);

    await simulation.start();
    await simulation.dragOver(target, towardsEdgeOf(target, 'top'));
    fixture.detectChanges();

    expect(source.getAttribute('data-dragging')).toBe('source');
    expect(target.getAttribute('data-drop-position')).toBe('top');

    await simulation.drop(target, towardsEdgeOf(target, 'top'));
    fixture.detectChanges();

    expect(source.hasAttribute('data-dragging')).toBe(false);
    expect(target.hasAttribute('data-drop-position')).toBe(false);
  });

  it('does not emit for a drop onto the dragged item itself', async () => {
    const source = item('list-one', 1);
    const simulation = new NativeDragSimulation(source);

    await simulation.start();
    await simulation.drop(source, towardsEdgeOf(source, 'top'));

    expect(host.drops).toEqual([]);
  });

  it('rejects items of another list, even with an equal item id', async () => {
    const foreignTarget = item('list-two', 1);
    const simulation = new NativeDragSimulation(item('list-one', 0));

    await simulation.start();
    await simulation.dragOver(foreignTarget, towardsEdgeOf(foreignTarget, 'top'));
    fixture.detectChanges();

    expect(foreignTarget.hasAttribute('data-drop-position')).toBe(false);

    await simulation.drop(foreignTarget, towardsEdgeOf(foreignTarget, 'top'));

    expect(host.drops).toEqual([]);
    expect(host.otherDrops).toEqual([]);
  });

  it('releases the sticky target and emits nothing when the drag leaves the list', async () => {
    const source = item('list-one', 0);
    const target = item('list-one', 2);
    const simulation = new NativeDragSimulation(source);

    await simulation.start();
    await simulation.dragOver(target, towardsEdgeOf(target, 'top'));
    // Outside the list bounds: over the document body, far away from both lists.
    await simulation.dragOver(document.body, { x: 900, y: 600 });
    fixture.detectChanges();

    expect(target.hasAttribute('data-drop-position')).toBe(false);

    await simulation.cancel();

    expect(host.drops).toEqual([]);
  });

  it('does not start a drag from an interactive descendant', async () => {
    const source = item('list-one', 0);
    const removeButton = source.querySelector<HTMLElement>('.remove-button')!;
    const simulation = new NativeDragSimulation(source);

    await simulation.start(centerOf(removeButton));
    fixture.detectChanges();

    expect(source.hasAttribute('data-dragging')).toBe(false);

    await simulation.drop(item('list-one', 2), towardsEdgeOf(item('list-one', 2), 'bottom'));

    expect(host.drops).toEqual([]);
  });

  it('registers items rendered after the initial view', async () => {
    host.ids.set(['a', 'b', 'c', 'd']);
    fixture.detectChanges();

    const added = item('list-one', 3);
    const simulation = new NativeDragSimulation(added);

    await simulation.start();
    await simulation.drop(item('list-one', 0), towardsEdgeOf(item('list-one', 0), 'top'));

    expect(intents(host.drops)).toEqual([{ sourceId: 'd', targetId: 'a', edge: 'top' }]);
  });

  it('keeps remaining items functional after items are removed', async () => {
    host.ids.set(['b', 'c']);
    fixture.detectChanges();

    const simulation = new NativeDragSimulation(item('list-one', 0));

    await simulation.start();
    await simulation.drop(item('list-one', 1), towardsEdgeOf(item('list-one', 1), 'bottom'));

    expect(intents(host.drops)).toEqual([{ sourceId: 'b', targetId: 'c', edge: 'bottom' }]);
  });

  it('warns and stays inert for an empty item id', async () => {
    const warn = vi.spyOn(console, 'warn').mockImplementation(() => undefined);

    try {
      host.ids.set(['']);
      fixture.detectChanges();

      expect(warn).toHaveBeenCalledWith(expect.stringContaining('non-empty item id'), expect.anything());

      const source = item('list-one', 0);
      const simulation = new NativeDragSimulation(source);

      await simulation.start();
      fixture.detectChanges();

      expect(source.hasAttribute('data-dragging')).toBe(false);
    } finally {
      warn.mockRestore();
    }
  });
});

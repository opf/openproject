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
// along with this program. If not, see <https://www.gnu.org/licenses/>.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { Injector } from '@angular/core';
import { fireEvent } from '@testing-library/dom';
import { States } from 'core-app/core/states/states.service';
import { onDestroySafely } from 'core-app/shared/helpers/angular/owned-ui-cleanup';
import { DragAndDropService } from 'core-app/shared/helpers/drag-and-drop/drag-and-drop.service';
import { buildTable, TableHarness } from '../testing/table-harness';
import { buildWorkPackage } from '../testing/work-package-fixture';
import { WorkPackageTable } from '../wp-fast-table';
import { DragAndDropTransformer } from './state/drag-and-drop-transformer';
import { TableEventComponent, TableHandlerRegistry } from './table-handler-registry';

describe('TableHandlerRegistry', () => {
  let harness:TableHarness;
  const tables:WorkPackageTable[] = [];

  beforeEach(async () => {
    harness = buildTable({ workPackages: [{ id: '1' }] });
    await harness.render();
  });

  afterEach(async () => {
    tables.splice(0).forEach((table) => table.destroy());
    await harness.destroy();
  });

  const unattachedTable = () => {
    const source = harness.table;
    const table = new WorkPackageTable(
      harness.injector, source.tableAndTimelineContainer, source.scrollContainer,
      source.tbody, source.timelineBody, source.timelineController, source.configuration,
    );
    tables.push(table);
    return table;
  };

  it('rejects a second registry attachment before adding any behavior', () => {
    const clicked = vi.fn();
    harness.outputs.itemClicked.subscribe(clicked);
    const refresh = vi.spyOn(harness.table, 'refreshRows');
    expect(() => new TableHandlerRegistry(harness.injector).attachTo({
      workPackageTable: harness.table, ...harness.outputs,
    })).toThrow('Table already attached or destroyed');
    harness.click('1');
    expect(clicked).toHaveBeenCalledOnce();
    harness.injector.get(States).workPackages.get('1').putValue(buildWorkPackage({ id: '1', subject: 'Changed' }));
    expect(refresh).toHaveBeenCalledOnce();
  });

  it.each(['direct', 'handle'])('converges repeated %s destruction with attachment cleanup', (mode) => {
    const table = unattachedTable();
    const own = vi.fn();
    const cleanup = vi.fn();
    class Transformer {
      constructor(_injector:Injector, attached:WorkPackageTable) {
        onDestroySafely(attached.destroyRef, cleanup);
      }
    }
    class Registry extends TableHandlerRegistry {
      protected readonly stateTransformers = [Transformer];
      protected eventHandlers = [() => ({
        EVENT: 'click' as const,
        SELECTOR: 'td',
        eventScope: (view:TableEventComponent) => view.workPackageTable.tbody,
        handleEvent: own,
      })];
    }
    const attachment = new Registry(harness.injector).attachTo({ workPackageTable: table, ...harness.outputs });
    fireEvent.click(harness.row('1').firstElementChild!);
    expect(own).toHaveBeenCalledOnce();
    own.mockClear();
    if (mode === 'direct') table.destroy();
    else attachment.destroy();
    table.destroy();
    attachment.destroy();
    attachment.destroy();
    expect(table.destroyed).toBe(true);
    expect(cleanup).toHaveBeenCalledOnce();
    fireEvent.click(harness.row('1').firstElementChild!);
    expect(own).not.toHaveBeenCalled();
    expect(() => new Registry(harness.injector).attachTo({ workPackageTable: table, ...harness.outputs }))
      .toThrow('Table already attached or destroyed');
  });

  it('makes captured drag callbacks inert before resolving services after disposal', () => {
    const table = unattachedTable();
    const registered = vi.spyOn(harness.injector.get(DragAndDropService), 'register');
    class Registry extends TableHandlerRegistry {
      protected readonly stateTransformers = [DragAndDropTransformer];
      protected eventHandlers = [];
    }
    new Registry(harness.injector).attachTo({ workPackageTable: table, ...harness.outputs });
    const member = registered.mock.calls[0][0];
    const row = harness.row('1');
    const handle = document.createElement('span');
    handle.className = 'wp-table--drag-and-drop-handle';
    table.destroy();
    const lookup = vi.spyOn(harness.injector, 'get');
    const preview = document.createElement('div');
    const complete = vi.fn();
    expect(member.canPickup(row, handle)).toBe(false);
    member.renderPreview?.(row, preview);
    member.onDragStarted?.(row);
    member.onMoved({ sourceId: '1', targetId: null, edge: null }, complete);
    expect(preview).toBeEmptyDOMElement();
    expect(complete).toHaveBeenCalledExactlyOnceWith(false);
    expect(lookup).not.toHaveBeenCalled();
    lookup.mockRestore();
  });

  it('destroys the partially constructed table when a transformer throws', () => {
    const table = unattachedTable();
    const cleanup = vi.fn();
    const error = new Error('transformer construction');
    class First {
      constructor(_injector:Injector, attached:WorkPackageTable) {
        onDestroySafely(attached.destroyRef, cleanup);
      }
    }
    class Failing {
      constructor() { throw error; }
    }
    class Registry extends TableHandlerRegistry {
      protected readonly stateTransformers = [First, Failing];
    }
    expect(() => new Registry(harness.injector).attachTo({ workPackageTable: table, ...harness.outputs })).toThrow(error);
    expect(table.destroyed).toBe(true);
    expect(cleanup).toHaveBeenCalledOnce();
  });
});

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

import { OpenprojectGridsModule } from 'core-app/shared/components/grids/openproject-grids.module';
import { CommonModule } from '@angular/common';
import { provideHttpClient } from '@angular/common/http';
import { provideHttpClientTesting } from '@angular/common/http/testing';
import { TestBed, ComponentFixture } from '@angular/core/testing';
import { Subject, of } from 'rxjs';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { CurrentProjectService } from 'core-app/core/current-project/current-project.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { TimezoneService } from 'core-app/core/datetime/timezone.service';
import { TurboRequestsService } from 'core-app/core/turbo/turbo-requests.service';
import { CollectionResource } from 'core-app/features/hal/resources/collection-resource';
import { SchemaResource } from 'core-app/features/hal/resources/schema-resource';
import { TimeEntryResource } from 'core-app/features/hal/resources/time-entry-resource';
import { HalResourceService } from 'core-app/features/hal/services/hal-resource.service';
import { GridAreaService } from 'core-app/shared/components/grids/grid/area.service';
import { GridDragAndDropService } from 'core-app/shared/components/grids/grid/drag-and-drop.service';
import { GridRemoveWidgetService } from 'core-app/shared/components/grids/grid/remove-widget.service';
import { ConfirmDialogService } from 'core-app/shared/components/modals/confirm-dialog/confirm-dialog.service';
import { OpIconComponent } from 'core-app/shared/components/icon/icon.component';
import { NoResultsComponent } from 'core-app/shared/components/no-results/no-results.component';
import { WidgetHeaderComponent } from '../../header/header.component';
import { WidgetMenuComponent } from '../../menu/widget-menu.component';
import { WidgetTimeEntriesProjectComponent } from '../project/time-entries-project.component';

describe('WidgetTimeEntriesProjectComponent rendering', () => {
  let fixture:ComponentFixture<WidgetTimeEntriesProjectComponent>;
  let entries$:Subject<CollectionResource<TimeEntryResource>>;
  let schema$:Subject<SchemaResource>;
  const request = vi.fn();
  const confirm = vi.fn();

  beforeEach(async () => {
    entries$ = new Subject();
    schema$ = new Subject();
    request.mockReset();
    confirm.mockReset();
    TestBed.overrideModule(OpenprojectGridsModule, {
      set: {
        imports: [CommonModule],
        declarations: [WidgetTimeEntriesProjectComponent, WidgetHeaderComponent, WidgetMenuComponent, NoResultsComponent, OpIconComponent],
        exports: [WidgetTimeEntriesProjectComponent], providers: [], schemas: [],
      },
    });
    TestBed.configureTestingModule({
      imports: [OpenprojectGridsModule],
      providers: [
        provideHttpClient(), provideHttpClientTesting(),
        { provide: ApiV3Service, useValue: { time_entries: { list: () => entries$, schema: { get: () => schema$ } } } },
        { provide: CurrentProjectService, useValue: { id: '1' } },
        { provide: I18nService, useValue: { t: (key:string) => key, toNumber: (n:number) => n.toFixed(2) } },
        { provide: TimezoneService, useValue: { toHours: (hours:string) => Number(hours.slice(2, -1)), formattedDate: (date:string) => date } },
        { provide: PathHelperService, useValue: { timeEntryEditDialog: (id:string) => `/time_entries/${id}/edit` } },
        { provide: ConfirmDialogService, useValue: { confirm } },
        { provide: TurboRequestsService, useValue: { request } },
        { provide: GridAreaService, useValue: { isEditable: false } },
        { provide: GridDragAndDropService, useValue: {} },
        { provide: GridRemoveWidgetService, useValue: {} },
      ],
    });
    TestBed.overrideTemplate(WidgetHeaderComponent, '');
    TestBed.overrideTemplate(WidgetMenuComponent, '');
    await TestBed.compileComponents();
    TestBed.inject(HalResourceService).registerResource('TimeEntry', { cls: TimeEntryResource });
    fixture = TestBed.createComponent(WidgetTimeEntriesProjectComponent);
    fixture.detectChanges();
  });

  function entry(id:number, allowed:boolean|null):TimeEntryResource {
    return TestBed.inject(HalResourceService).createHalResourceOfType<TimeEntryResource>('TimeEntry', {
      id, spentOn: '2026-10-29', hours: 'PT2H', comment: { raw: 'Work' },
      _links: {
        self: { href: `/api/v3/time_entries/${id}` },
        project: { href: '/api/v3/projects/1', title: 'Project' },
        ...(allowed ? {
          updateImmediately: { href: `/api/v3/time_entries/${id}`, method: 'patch' },
          delete: { href: `/api/v3/time_entries/${id}`, method: 'delete' },
        } : allowed === null ? { delete: { href: null, method: 'delete' } } : {}),
      },
    }, true);
  }

  async function load(entries:TimeEntryResource[]) {
    const factory = TestBed.inject(HalResourceService);
    entries$.next(factory.createHalResource<CollectionResource<TimeEntryResource>>({ count: entries.length, _embedded: { elements: entries } }, true));
    if (entries.length) {
      schema$.next(factory.createHalResource<SchemaResource>({
        activity: { name: 'Activity' }, entity: { name: 'Entity' }, comment: { name: 'Comment' }, hours: { name: 'Hours' },
      }, true));
    }
    await Promise.resolve();
    fixture.detectChanges();
  }

  it('waits for entries before rendering the empty state', async () => {
    expect(fixture.nativeElement.querySelector('op-no-results')).toBeNull();
    expect(fixture.nativeElement.querySelector('table')).toBeNull();
    await load([]);
    expect(fixture.nativeElement.querySelector('op-no-results')).toHaveTextContent('js.grid.widgets.time_entries_list.no_results');
  });

  it('waits for schema labels before rendering grouped rows', async () => {
    const factory = TestBed.inject(HalResourceService);
    entries$.next(factory.createHalResource<CollectionResource<TimeEntryResource>>({ count: 1, _embedded: { elements: [entry(1, false)] } }, true));
    fixture.detectChanges();
    expect(fixture.nativeElement.querySelector('table')).toBeNull();
    schema$.next(factory.createHalResource<SchemaResource>({ activity: { name: 'Activity' }, entity: { name: 'Entity' }, comment: { name: 'Comment' }, hours: { name: 'Hours' } }, true));
    await Promise.resolve();
    fixture.detectChanges();
    expect(fixture.nativeElement.querySelector('table')).toHaveTextContent('Activity');
    expect(fixture.nativeElement.querySelectorAll('tbody tr')).toHaveLength(2);
  });

  it.each([false, null])('does not confirm a delete without capability (%s)', (capability) => {
    confirm.mockReturnValue(new Promise(() => undefined));
    fixture.componentInstance.deleteIfConfirmed(new Event('click', { cancelable: true }), entry(1, capability));
    expect(confirm).not.toHaveBeenCalled();
  });

  it('executes an allowed delete only after confirmation', async () => {
    const allowed = entry(2, true);
    await load([allowed]);
    let finish!:() => void;
    confirm.mockReturnValue(new Promise<void>((resolve) => { finish = resolve; }));
    const deletion = vi.spyOn(TestBed.inject(HalResourceService), 'request').mockReturnValue(of(allowed));
    fixture.nativeElement.querySelector('a[title="js.button_delete"]').click();
    expect(confirm).toHaveBeenCalledOnce();
    expect(deletion).not.toHaveBeenCalled();
    finish();
    await Promise.resolve();
    await Promise.resolve();
    expect(deletion).toHaveBeenCalledWith('delete', '/api/v3/time_entries/2', undefined, undefined);
  });

  it('hides denied actions and does not execute allowed actions during rendering', async () => {
    const denied = entry(1, false);
    const allowed = entry(2, true);
    const deletion = vi.spyOn(TestBed.inject(HalResourceService), 'request');
    await load([denied, allowed]);
    expect(fixture.nativeElement.querySelectorAll('a[title="js.button_edit"]')).toHaveLength(1);
    expect(fixture.nativeElement.querySelectorAll('a[title="js.button_delete"]')).toHaveLength(1);
    expect(deletion).not.toHaveBeenCalled();
    expect(fixture.nativeElement.querySelectorAll('tbody tr')).toHaveLength(3);
    fixture.nativeElement.querySelector('a[title="js.button_edit"]').click();
    expect(request).toHaveBeenCalledWith('/time_entries/2/edit', { method: 'GET' });
  });
});

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

import { ChangeDetectionStrategy, Component, CUSTOM_ELEMENTS_SCHEMA, Injector } from '@angular/core';
import { CommonModule } from '@angular/common';
import { TestBed, ComponentFixture } from '@angular/core/testing';
import { DragDropModule } from '@angular/cdk/drag-drop';
import { DynamicModule } from 'ng-dynamic-component';
import { Observable, of, Subject } from 'rxjs';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { BrowserDetector } from 'core-app/core/browser/browser-detector.service';
import { GridResource } from 'core-app/features/hal/resources/grid-resource';
import { GridWidgetResource } from 'core-app/features/hal/resources/grid-widget-resource';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { HalResourceService } from 'core-app/features/hal/services/hal-resource.service';
import { SchemaResource } from 'core-app/features/hal/resources/schema-resource';
import { ToastService } from 'core-app/shared/components/toaster/toast.service';
import { OpModalService } from 'core-app/shared/components/modal/modal.service';
import { AbstractWidgetComponent } from '../widgets/abstract-widget.component';
import { GridWidgetsService } from '../widgets/widgets.service';
import { GridComponent, GRID_PROVIDERS } from './grid.component';
import { GridWidgetArea } from '../areas/grid-widget-area';
import { GridDragAndDropService } from './drag-and-drop.service';
import { GridAddWidgetService } from './add-widget.service';
import { GridResizeService } from './resize.service';
import { SchemaCacheService } from 'core-app/core/schemas/schema-cache.service';
import { WidgetChangeset } from '../widgets/widget-changeset';
import { GridAreaService } from './area.service';
import { AddGridWidgetModalComponent } from '../widgets/add/add.modal';

interface WidgetPicker {
  chosenWidget:Pick<NonNullable<AddGridWidgetModalComponent['chosenWidget']>, 'identifier'|'properties'>;
  closingEvent:Observable<unknown>;
}

@Component({
  template: '<span>{{ resource.options.name }}</span>',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
class TestWidgetComponent extends AbstractWidgetComponent {}

function initialize(resource:HalResource) {
  Object.assign(resource, resource.$source);
}

function gridResource(names = ['First', 'Second']):GridResource {
  return new GridResource(TestBed.inject(Injector), {
    id: '1',
    rowCount: names.length,
    columnCount: 1,
    updateImmediately: vi.fn(),
    widgets: names.map((name, index) => ({
      id: String(index + 1),
      identifier: 'test',
      startRow: index + 1,
      endRow: index + 2,
      startColumn: 1,
      endColumn: 2,
      options: { name },
    })),
  }, true, initialize, 'Grid');
}

describe('Grid rendering', () => {
  let fixture:ComponentFixture<GridComponent>;
  let layout:GridAreaService;
  let response:Subject<GridResource>;
  let grid:GridResource;
  let formPost:ReturnType<typeof vi.fn<() => Observable<{ schema:SchemaResource }>>>;
  let showModal:ReturnType<typeof vi.fn<() => Observable<WidgetPicker>>>;
  let createResource:ReturnType<typeof vi.fn<() => GridWidgetResource>>;
  let patch:ReturnType<typeof vi.fn<(resource:object) => Subject<GridResource>>>;
  const addError = vi.fn<ToastService['addError']>();

  beforeEach(async () => {
    response = new Subject<GridResource>();
    patch = vi.fn(() => response);
    formPost = vi.fn(() => of({ schema: { widgets: { writable: true } } as unknown as SchemaResource }));
    showModal = vi.fn();
    createResource = vi.fn<() => GridWidgetResource>();
    addError.mockClear();
    TestBed.configureTestingModule({
      imports: [CommonModule, DragDropModule, DynamicModule, TestWidgetComponent],
      declarations: [GridComponent],
      schemas: [CUSTOM_ELEMENTS_SCHEMA],
      providers: [
        { provide: I18nService, useValue: { t: (key:string) => key } },
        { provide: ApiV3Service, useValue: { grids: { id: () => ({
          form: { post: formPost },
          patch,
        }) } } },
        { provide: GridWidgetsService, useValue: { registered: [{ identifier: 'test', component: TestWidgetComponent }] } },
        { provide: ToastService, useValue: { addSuccess: vi.fn(), addError } },
        { provide: BrowserDetector, useValue: { isMobile: false } },
        { provide: OpModalService, useValue: { show: showModal } },
        { provide: SchemaCacheService, useValue: {} },
        { provide: HalResourceService, useValue: { createHalResource: createResource } },
      ],
    }).overrideComponent(GridComponent, { add: { providers: GRID_PROVIDERS } });
    fixture = TestBed.createComponent(GridComponent);
    layout = fixture.debugElement.injector.get(GridAreaService);
    grid = gridResource();
    fixture.componentRef.setInput('grid', grid);
    await fixture.whenStable();
  });

  it('renders registered widgets through the dynamic host', () => {
    expect(fixture.nativeElement as HTMLElement).toHaveTextContent('First');
    expect(fixture.nativeElement as HTMLElement).toHaveTextContent('Second');
  });

  it.each([2, 20])('removes a widget from a %s-widget grid before persistence completes', async (count) => {
    grid = gridResource(['First', 'Second', ...Array.from({ length: count - 2 }, (_, index) => `Extra ${index}`)]);
    fixture.componentRef.setInput('grid', grid);
    await fixture.whenStable();
    const remainingElement = (fixture.nativeElement as HTMLElement).querySelectorAll('.grid--area.-widgeted')[1];
    const saving = layout.removeWidget(grid.widgets[0]);
    await fixture.whenStable();
    expect(fixture.nativeElement as HTMLElement).not.toHaveTextContent('First');
    expect(fixture.nativeElement as HTMLElement).toHaveTextContent('Second');
    expect((fixture.nativeElement as HTMLElement).querySelector('.grid--area.-widgeted')).toBe(remainingElement);
    response.next(grid);
    await saving;
    await fixture.whenStable();
  });

  it('keeps the optimistic layout and reports a rejected save', async () => {
    const saving = layout.removeWidget(grid.widgets[0]);
    const rejected = saving.catch((error:unknown) => error);
    response.error(new Error('Save failed'));
    expect(await rejected).toEqual(new Error('Save failed'));
    await fixture.whenStable();
    expect(fixture.nativeElement as HTMLElement).not.toHaveTextContent('First');
    expect(addError).toHaveBeenCalledWith('Save failed');
  });

  it('adds a widget before persistence and keeps its element when its saved resource arrives', async () => {
    const added = gridResource(['Added']).widgets[0];
    vi.spyOn(added, 'id', 'get').mockReturnValue(null);
    added.startRow = 3;
    added.endRow = 4;
    layout.addWidget(new GridWidgetArea(added));
    const saving = layout.rebuildAndPersist();
    await fixture.whenStable();
    expect(fixture.nativeElement as HTMLElement).toHaveTextContent('Added');
    const elements = (fixture.nativeElement as HTMLElement).querySelectorAll('.grid--area.-widgeted');
    const saved = gridResource(['First', 'Second', 'Saved']);
    response.next(saved);
    await saving;
    await fixture.whenStable();
    expect(fixture.nativeElement as HTMLElement).toHaveTextContent('Saved');
    expect((fixture.nativeElement as HTMLElement).querySelectorAll('.grid--area.-widgeted')[2]).toBe(elements[2]);
    expect(layout.widgetAreas()[2].widget).toBeInstanceOf(GridWidgetResource);
  });

  it('shows drag state and resets geometry when aborted', async () => {
    const drag = fixture.debugElement.injector.get(GridDragAndDropService);
    const area = layout.widgetAreas()[0];
    drag.start(area);
    await fixture.whenStable();
    expect((fixture.nativeElement as HTMLElement).querySelector('.-dragged')).not.toBeNull();
    expect((fixture.nativeElement as HTMLElement).querySelector('.-placeholder')).not.toBeNull();
    await new Promise((resolve) => setTimeout(resolve, 20));
    layout.setMousedOverArea(layout.gridAreas()[2]);
    await fixture.whenStable();
    expect(drag.placeholderArea?.startRow).toBe(3);
    drag.abort();
    await fixture.whenStable();
    expect((fixture.nativeElement as HTMLElement).querySelector('.-placeholder')).toBeNull();
    expect(area.startRow).toBe(1);
  });

  it('persists a drop and clears its placeholder while the save is pending', async () => {
    const drag = fixture.debugElement.injector.get(GridDragAndDropService);
    drag.start(layout.widgetAreas()[0]);
    await new Promise((resolve) => setTimeout(resolve, 20));
    layout.setMousedOverArea(layout.gridAreas()[2]);
    drag.drop();
    await fixture.whenStable();
    expect(patch).toHaveBeenCalledOnce();
    expect((fixture.nativeElement as HTMLElement).querySelector('.-placeholder')).toBeNull();
    expect((fixture.nativeElement as HTMLElement).querySelector('.-dragged')).toBeNull();
    response.next(grid);
    await fixture.whenStable();
  });

  it('renders resize previews and restores them on abort', async () => {
    const wideGrid = gridResource();
    wideGrid.columnCount = 2;
    fixture.componentRef.setInput('grid', wideGrid);
    await fixture.whenStable();
    const resize = fixture.debugElement.injector.get(GridResizeService);
    const area = layout.widgetAreas()[0];
    resize.start(area);
    await fixture.whenStable();
    expect((fixture.nativeElement as HTMLElement).querySelector('.-resizing')).not.toBeNull();
    layout.setMousedOverArea(layout.gridAreas()[1]);
    resize.moving();
    await fixture.whenStable();
    expect(area.endColumn).toBe(3);
    expect((fixture.nativeElement as HTMLElement).querySelector<HTMLElement>('.-resizing')?.style.gridColumnEnd).toBe(String(area.gridEndColumn));
    resize.abort();
    await fixture.whenStable();
    expect((fixture.nativeElement as HTMLElement).querySelector('.-resizing')).toBeNull();
    expect(area.startRow).toBe(area.widget.startRow);
    expect(area.endColumn).toBe(2);
  });

  it('renders help mode when the last widget is removed', async () => {
    const emptyGrid = gridResource(['Only']);
    fixture.componentRef.setInput('grid', emptyGrid);
    await fixture.whenStable();
    const saving = layout.removeWidget(emptyGrid.widgets[0]);
    await fixture.whenStable();
    expect((fixture.nativeElement as HTMLElement).querySelector('.-widgeted')).toBeNull();
    expect((fixture.nativeElement as HTMLElement).querySelector('.-help-mode')).not.toBeNull();
    response.next(emptyGrid);
    await saving;
  });

  it('does not expose add or resize controls for a read-only grid', async () => {
    const readonlyGrid = gridResource();
    delete readonlyGrid.updateImmediately;
    fixture.componentRef.setInput('grid', readonlyGrid);
    await fixture.whenStable();
    expect((fixture.nativeElement as HTMLElement).querySelector('.grid--widget-add')).toBeNull();
    expect((fixture.nativeElement as HTMLElement).querySelector('op-resizer')).toBeNull();
  });

  it('does not restore widgets from an older save response', async () => {
    const oldResponse = new Subject<GridResource>();
    patch.mockReturnValueOnce(oldResponse);
    const firstSave = layout.persist();
    const staleGrid = gridResource();
    const secondSave = layout.removeWidget(grid.widgets[0]);
    response.next(grid);
    await secondSave;
    oldResponse.next(staleGrid);
    await firstSave;
    await fixture.whenStable();
    expect(grid.widgets).toHaveLength(1);
    expect(fixture.nativeElement as HTMLElement).not.toHaveTextContent('First');
  });

  it('ignores a previous grid save after replacing the input', async () => {
    const saving = layout.persist();
    fixture.componentRef.setInput('grid', gridResource(['Replacement']));
    await fixture.whenStable();
    response.next(grid);
    await saving;
    await fixture.whenStable();
    expect(fixture.nativeElement as HTMLElement).toHaveTextContent('Replacement');
    expect(fixture.nativeElement as HTMLElement).not.toHaveTextContent('First');
  });


  it('retains both option changes when initial widgets save concurrently', async () => {
    const firstChangeset = new WidgetChangeset(grid.widgets[0]);
    firstChangeset.setValue('options', { name: 'First', queryId: '10' });
    const firstSave = layout.saveWidgetChangeset(firstChangeset);
    const secondChangeset = new WidgetChangeset(grid.widgets[1]);
    secondChangeset.setValue('options', { name: 'Second', queryId: '20' });
    const secondSave = layout.saveWidgetChangeset(secondChangeset);
    expect(patch.mock.calls[1][0]).toMatchObject({ widgets: [
      { options: { queryId: '10' } },
      { options: { queryId: '20' } },
    ] });
    response.next(grid);
    await Promise.all([firstSave, secondSave]);
  });

  it('returns to idle after a failed resize and accepts another interaction', async () => {
    const wideGrid = gridResource();
    wideGrid.columnCount = 2;
    fixture.componentRef.setInput('grid', wideGrid);
    await fixture.whenStable();
    const resize = fixture.debugElement.injector.get(GridResizeService);
    const area = layout.widgetAreas()[0];
    resize.start(area);
    layout.setMousedOverArea(layout.gridAreas()[1]);
    resize.moving();
    fixture.componentInstance.resizeEnd(area);
    response.error(new Error('Resize failed'));
    await fixture.whenStable();
    expect(resize.currentlyResizing).toBe(false);
    expect(addError).toHaveBeenCalledWith('Resize failed');
    resize.start(area);
    await fixture.whenStable();
    expect((fixture.nativeElement as HTMLElement).querySelector('.-resizing')).not.toBeNull();
    resize.abort();
  });


  it('adds a selected widget through the modal while saving is pending', async () => {
    const added = gridResource(['Selected']).widgets[0];
    added.id = '3';
    added.startRow = 3;
    added.endRow = 4;
    createResource.mockReturnValueOnce(added);
    showModal.mockReturnValue(of({
      chosenWidget: { identifier: 'test', properties: { name: 'Selected' } },
      closingEvent: of(undefined),
    }));
    const adding = fixture.debugElement.injector.get(GridAddWidgetService).widget(layout.gridAreas()[2]);
    await Promise.resolve();
    await fixture.whenStable();
    expect(fixture.nativeElement as HTMLElement).toHaveTextContent('Selected');
    response.error(new Error('Add failed'));
    expect(await adding).toBeNull();
    await fixture.whenStable();
    expect(addError).toHaveBeenCalledWith('Add failed');
    expect(fixture.nativeElement as HTMLElement).toHaveTextContent('Selected');
  });

  it('ignores an obsolete schema and unsubscribes from pending schema requests on destruction', async () => {
    const oldSchema = new Subject<{ schema:SchemaResource }>();
    const currentSchema = new Subject<{ schema:SchemaResource }>();
    formPost.mockReturnValueOnce(oldSchema).mockReturnValueOnce(currentSchema);
    fixture.componentRef.setInput('grid', gridResource(['Older']));
    await fixture.whenStable();
    fixture.componentRef.setInput('grid', gridResource(['Current']));
    await fixture.whenStable();
    const schema = { widgets: { writable: true } } as unknown as SchemaResource;
    currentSchema.next({ schema });
    oldSchema.next({ schema: {} as SchemaResource });
    expect(layout.schema()).toBe(schema);
    expect(layout.$schema.value).toBe(schema);
    fixture.destroy();
    expect(oldSchema.observed).toBe(false);
    expect(currentSchema.observed).toBe(false);
  });

  it('cancels a drag when the grid input changes', async () => {
    const drag = fixture.debugElement.injector.get(GridDragAndDropService);
    drag.start(layout.widgetAreas()[0]);
    fixture.componentRef.setInput('grid', gridResource(['Replacement']));
    await fixture.whenStable();
    expect(drag.currentlyDragging).toBe(false);
    expect((fixture.nativeElement as HTMLElement).querySelector('.-placeholder')).toBeNull();
    expect(fixture.nativeElement as HTMLElement).toHaveTextContent('Replacement');
  });


  it('keeps an earlier successful creation ID when a newer save fails', async () => {
    const added = gridResource(['Added']).widgets[0];
    let savedId:string|null = null;
    vi.spyOn(added, 'id', 'get').mockImplementation(() => savedId);
    vi.spyOn(added, 'id', 'set').mockImplementation((id) => { savedId = id; });
    added.startRow = 3;
    added.endRow = 4;
    layout.addWidget(new GridWidgetArea(added));
    const oldResponse = new Subject<GridResource>();
    patch.mockReturnValueOnce(oldResponse);
    const firstSave = layout.persist();
    added.options = { name: 'Local edit' };
    const secondSave = layout.persist().catch((error:unknown) => error);
    response.error(new Error('Latest failed'));
    await secondSave;
    oldResponse.next(gridResource(['First', 'Second', 'Server name']));
    await firstSave;
    await fixture.whenStable();
    expect(layout.widgetAreas()[2].widget.id).toBe('3');
    expect(layout.widgetAreas()[2].widget.options.name).toBe('Local edit');
    expect(fixture.nativeElement as HTMLElement).toHaveTextContent('Local edit');
    const retryResponse = new Subject<GridResource>();
    patch.mockReturnValueOnce(retryResponse);
    const retry = layout.persist();
    expect(patch.mock.calls[2][0]).toMatchObject({ widgets: [
      { id: '1' }, { id: '2' }, { id: '3', options: { name: 'Local edit' } },
    ] });
    retryResponse.next(grid);
    await retry;
  });

  it('discards a widget selection opened for a previous grid', async () => {
    const closingEvent = new Subject<void>();
    const added = gridResource(['Obsolete']).widgets[0];
    createResource.mockReturnValueOnce(added);
    showModal.mockReturnValue(of({
      chosenWidget: { identifier: 'test', properties: { name: 'Obsolete' } },
      closingEvent,
    }));
    const adding = fixture.debugElement.injector.get(GridAddWidgetService).widget(layout.gridAreas()[0]);
    fixture.componentRef.setInput('grid', gridResource(['Replacement']));
    await fixture.whenStable();
    closingEvent.next();
    await Promise.resolve();
    await fixture.whenStable();
    expect(patch).not.toHaveBeenCalled();
    expect(await adding).toBeNull();
    expect(fixture.nativeElement as HTMLElement).not.toHaveTextContent('Obsolete');
  });


  it('discards a widget selection after its grid is destroyed', async () => {
    const closingEvent = new Subject<void>();
    showModal.mockReturnValue(of({ chosenWidget: { identifier: 'test' }, closingEvent }));
    const adding = fixture.debugElement.injector.get(GridAddWidgetService).widget(layout.gridAreas()[0]);
    fixture.destroy();
    closingEvent.next();
    expect(await adding).toBeNull();
    expect(createResource).not.toHaveBeenCalled();
    expect(patch).not.toHaveBeenCalled();
  });


  it('adopts the latest creation ID when both overlapping saves succeed oldest-first', async () => {
    const added = gridResource(['Added']).widgets[0];
    vi.spyOn(added, 'id', 'get').mockReturnValue(null);
    added.startRow = 3;
    added.endRow = 4;
    layout.addWidget(new GridWidgetArea(added));
    const oldResponse = new Subject<GridResource>();
    patch.mockReturnValueOnce(oldResponse);
    const firstSave = layout.persist();
    const secondSave = layout.persist();
    oldResponse.next(gridResource(['First', 'Second', 'Older creation']));
    await firstSave;
    expect(layout.widgetAreas()[2].widget.id).toBe('3');
    const latest = gridResource(['First', 'Second', 'Latest creation']);
    latest.widgets[2].id = '4';
    response.next(latest);
    await secondSave;
    await fixture.whenStable();
    expect(layout.widgetAreas()[2].widget.id).toBe('4');
    expect(fixture.nativeElement as HTMLElement).toHaveTextContent('Latest creation');
    const retryResponse = new Subject<GridResource>();
    patch.mockReturnValueOnce(retryResponse);
    const retry = layout.persist();
    expect(patch.mock.calls[2][0]).toMatchObject({ widgets: [{ id: '1' }, { id: '2' }, { id: '4' }] });
    retryResponse.next(latest);
    await retry;
  });


  it.each([
    [0, 1, 2], [1, 0, 2], [2, 0, 1], [2, 1, 0], [0, 2, 1], [1, 2, 0],
  ])('keeps the newest successful creation ID with completion order %s/%s/%s', async (...order:number[]) => {
    const added = gridResource(['Added']).widgets[0];
    vi.spyOn(added, 'id', 'get').mockReturnValue(null);
    added.startRow = 3;
    added.endRow = 4;
    layout.addWidget(new GridWidgetArea(added));
    const responses = [new Subject<GridResource>(), new Subject<GridResource>(), new Subject<GridResource>()];
    responses.forEach((subject) => patch.mockReturnValueOnce(subject));
    const saves = responses.map(() => layout.persist().catch((error:unknown) => error));
    for (const index of order) {
      if (index === 2) {
        responses[index].error(new Error('Newest save failed'));
      } else {
        const saved = gridResource(['First', 'Second', 'Server name']);
        saved.widgets[2].id = String(index + 3);
        responses[index].next(saved);
      }
      await saves[index];
    }
    await fixture.whenStable();
    expect(layout.widgetAreas()[2].widget.id).toBe('4');
    expect(layout.widgetAreas()[2].widget.options.name).toBe('Added');
    const retryResponse = new Subject<GridResource>();
    patch.mockReturnValueOnce(retryResponse);
    const retry = layout.persist();
    expect(patch.mock.calls[3][0]).toMatchObject({ widgets: [{ id: '1' }, { id: '2' }, { id: '4' }] });
    retryResponse.next(grid);
    await retry;
  });

});

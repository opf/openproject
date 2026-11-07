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

import { range } from 'lodash-es';
import { computed, DestroyRef, Injectable, inject, signal } from '@angular/core';
import { GridWidgetArea } from 'core-app/shared/components/grids/areas/grid-widget-area';
import { GridArea } from 'core-app/shared/components/grids/areas/grid-area';
import { GridGap } from 'core-app/shared/components/grids/areas/grid-gap';
import { GridResource } from 'core-app/features/hal/resources/grid-resource';
import { GridWidgetResource } from 'core-app/features/hal/resources/grid-widget-resource';
import { SchemaResource } from 'core-app/features/hal/resources/schema-resource';
import { WidgetChangeset } from 'core-app/shared/components/grids/widgets/widget-changeset';
import { ToastService } from 'core-app/shared/components/toaster/toast.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { BehaviorSubject, firstValueFrom } from 'rxjs';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { ApiV3GridForm } from 'core-app/core/apiv3/endpoints/grids/apiv3-grid-form';
import { map } from 'rxjs/operators';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';

interface GridWidgetPayload {
  id:string;
  [key:string]:unknown;
}

interface GridPatchPayload {
  id:string;
  widgets?:GridWidgetPayload[];
  [key:string]:unknown;
}

type PendingWidgetCreation = Pick<GridWidgetResource, 'identifier'|'startRow'|'startColumn'> & { area:GridWidgetArea };

type ScrollIntoViewIfNeededElement = HTMLElement&{ scrollIntoViewIfNeeded?:() => void };

@Injectable()
export class GridAreaService {
  private apiV3Service = inject(ApiV3Service);
  private toastService = inject(ToastService);
  private i18n = inject(I18nService);

  private readonly destroyRef = inject(DestroyRef);
  private readonly resourceState = signal<GridResource|undefined>(undefined);
  private readonly schemaState = signal<SchemaResource|undefined>(undefined);
  private readonly columnCount = signal(0);
  private readonly rowCount = signal(0);
  private readonly cells = signal<readonly GridArea[]>([]);
  private readonly gaps = signal<readonly GridArea[]>([]);
  private readonly widgets = signal<readonly GridWidgetArea[]>([]);
  private readonly hoveredArea = signal<GridArea|null>(null);
  private readonly helpMode = signal(false);
  private saveSequence = 0;
  private readonly reconciledSequences = new WeakMap<GridWidgetArea, number>();

  readonly gridResource = this.resourceState.asReadonly();
  readonly schema = this.schemaState.asReadonly();
  readonly numColumns = this.columnCount.asReadonly();
  readonly numRows = this.rowCount.asReadonly();
  readonly gridAreas = this.cells.asReadonly();
  readonly gridGaps = this.gaps.asReadonly();
  readonly widgetAreas = this.widgets.asReadonly();
  readonly mousedOverArea = this.hoveredArea.asReadonly();
  readonly gridAreaIds = computed(() => this.gridAreas().map((area) => area.guid));
  readonly isEditable = computed(() => this.gridResource()?.updateImmediately !== undefined);
  readonly isSingleCell = computed(() => this.numRows() === 1 && this.numColumns() === 1 && this.widgetAreas().length === 0);
  readonly inHelpMode = computed(() => this.helpMode() || this.isSingleCell());
  readonly widgetAreasForDisplay = computed(() => {
    const index = (area:GridWidgetArea) => (area.startRow - 1) * this.numColumns() + area.startColumn;
    return [...this.widgetAreas()].sort((a, b) => index(a) - index(b)
      || (a.widget.id ?? a.guid).localeCompare(b.widget.id ?? b.guid));
  });

  readonly $schema = new BehaviorSubject<SchemaResource|null>(null);
  readonly $mousedOverArea = new BehaviorSubject<GridArea|null>(null);

  initialize(resource:GridResource) {
    this.saveSequence++;
    this.resourceState.set(resource);
    this.schemaState.set(undefined);
    this.$schema.next(null);
    this.rowCount.set(resource.rowCount);
    this.columnCount.set(resource.columnCount);
    this.widgets.set(resource.widgets.map((widget) => new GridWidgetArea(widget)));
    this.buildAreas();
    this.fetchSchema(resource);
  }

  private get resource():GridResource {
    const resource = this.gridResource();
    if (!resource) {
      throw new Error('Grid is not initialized');
    }
    return resource;
  }

  addWidget(area:GridWidgetArea) {
    this.resource.widgets = [...this.resource.widgets, area.widget];
    this.widgets.update((areas) => [...areas, area]);
  }

  extendRows(endRow:number) {
    this.rowCount.update((rows) => Math.max(rows, endRow));
  }

  publishGeometry() {
    this.widgets.update((areas) => [...areas]);
  }

  public setMousedOverArea(area:GridArea|null) {
    this.hoveredArea.set(area);

    this.$mousedOverArea.next(area);
  }

  public cleanupUnusedAreas() {
    // array containing Numbers from this.numRows() to 1
    let unusedRows = range(this.numRows(), 0, -1);

    this.widgetAreas().forEach((widget) => {
      unusedRows = unusedRows.filter((item) => item !== widget.startRow);
    });

    unusedRows.forEach((number) => {
      if (this.numRows() > 1) {
        this.removeRow(number);
      }
    });

    let unusedColumns = range(this.numColumns(), 0, -1);

    this.widgetAreas().forEach((widget) => {
      unusedColumns = unusedColumns.filter((item) => item !== widget.startColumn);
    });

    unusedColumns.forEach((number) => {
      if (this.numColumns() > 1) {
        this.removeColumn(number);
      }
    });
  }

  public buildAreas() {
    this.cells.set(this.buildGridAreas());
    this.gaps.set(this.buildGridGaps());
    this.publishGeometry();
  }

  public rebuildAndPersist():Promise<GridResource> {
    return this.persist();
  }

  public persist() {
    this.rowCount.set((this.widgetAreas().map((area) => area.endRow).sort((a, b) => a - b).pop() ?? 2) - 1);
    this.resource.rowCount = this.numRows();
    this.resource.columnCount = this.numColumns();

    this.writeAreaChangesToWidgets();
    this.buildAreas();
    return this.saveGrid(this.resource, this.schema());
  }

  public async saveWidgetChangeset(changeset:WidgetChangeset):Promise<GridResource> {
    const payload = ApiV3GridForm.extractPayload(this.resource, this.schema()) as GridPatchPayload;
    const gridId = this.resource.id;

    const payloadWidget = payload.widgets?.find((widget) => widget.id === changeset.pristineResource.id);

    if (!payloadWidget) {
      throw new Error(`Missing widget payload for ${changeset.pristineResource.id}`);
    }

    if (!gridId) {
      throw new Error('Missing grid id');
    }

    Object.assign(payloadWidget, changeset.changes);

    /* Special case for the initial creation of the MyPage with two widgets:
     * Synchronously update the in-memory widget resource so that concurrent
     * saveWidgetChangeset calls see the updated state before the async save completes.
     * Without this, the second call reads stale widget options and overwrites the
     * first widget's queryId/queryProps with the old values, permanently breaking it. */
    const inMemoryWidget = this.resource.widgets.find((w) => w.id === changeset.pristineResource.id);
    if (inMemoryWidget) {
      Object.assign(inMemoryWidget, changeset.changes);
    }

    // Adding the id so that the url can be deduced
    payload.id = gridId;

    this.publishGeometry();
    return this.saveGrid(payload);
  }

  public isGap(area:GridArea) {
    return area instanceof GridGap;
  }

  public toggleHelpMode() {
    this.helpMode.update((value) => !value);
  }

  // This is a hacky way to have the placeholder in the viewport.
  // It is a noop for firefox and edge as both do not support scrollIntoViewIfNeeded.
  // But as scrollIntoView will always readjust the viewport, the result would be an unbearable flicker
  // which causes e.g. dragging to be impossible.
  public scrollPlaceholderIntoView() {
    const placeholder = document.querySelector<ScrollIntoViewIfNeededElement>('.grid--area.-placeholder')!;

    if (placeholder.scrollIntoViewIfNeeded) {
      setTimeout(() => placeholder.scrollIntoViewIfNeeded!());
    }
  }

  private async saveGrid(resource:GridResource|GridPatchPayload, schema?:SchemaResource):Promise<GridResource> {
    const currentResource = this.resource;
    const sequence = ++this.saveSequence;
    const creations:PendingWidgetCreation[] = this.widgetAreas()
      .filter((area) => !area.widget.id)
      .map((area) => ({ area, identifier: area.widget.identifier, startRow: area.widget.startRow, startColumn: area.widget.startColumn }));
    const subscription = this
      .apiV3Service
      .grids
      .id(resource)
      .patch(resource, schema)
      .pipe(
        map((updatedGrid) => {
          if (!this.destroyRef.destroyed && this.gridResource() === currentResource) {
            if (sequence === this.saveSequence) {
              this.assignAreasWidget(updatedGrid, creations, sequence);
            } else {
              this.reconcileCreatedWidgets(updatedGrid, creations, sequence);
            }
          }
          this.toastService.addSuccess(this.i18n.t('js.notice_successful_update'));

          return updatedGrid;
        }),
      );

    return firstValueFrom(subscription)
      .catch((error:unknown) => {
        this.toastService.addError(error instanceof Error ? error.message : String(error));
        throw error;
      });
  }

  private reconcileCreatedWidgets(savedGrid:GridResource, creations:PendingWidgetCreation[], sequence:number) {
    const takenIds = new Set(this.widgetAreas().map((area) => area.widget.id));
    for (const creation of creations) {
      const { area } = creation;
      if (!this.widgetAreas().includes(area) || (this.reconciledSequences.get(area) ?? 0) >= sequence) {
        continue;
      }
      const saved = savedGrid.widgets.find((widget) => (!takenIds.has(widget.id) || widget.id === area.widget.id)
        && widget.identifier === creation.identifier
        && widget.startRow === creation.startRow
        && widget.startColumn === creation.startColumn);
      if (!saved) {
        continue;
      }
      const local = area.widget;
      area.widget = Object.assign(saved, {
        startRow: local.startRow,
        endRow: local.endRow,
        startColumn: local.startColumn,
        endColumn: local.endColumn,
        options: local.options,
        grid: this.resource,
      });
      takenIds.add(saved.id);
      this.reconciledSequences.set(area, sequence);
    }
    this.resource.widgets = this.widgetAreas().map((area) => area.widget);
    this.publishGeometry();
  }

  private assignAreasWidget(newGrid:GridResource, creations:PendingWidgetCreation[], sequence:number) {
    const takenIds = new Set(this.widgetAreas().map((area) => area.widget.id));
    this.widgetAreas().forEach((area) => {
      const creation = creations.find((candidate) => candidate.area === area);
      const newWidget = newGrid.widgets.find((widget) => area.widget.id && widget.id === area.widget.id)
        ?? (creation && newGrid.widgets.find((widget) => !takenIds.has(widget.id)
          && widget.identifier === creation.identifier
          && widget.startRow === creation.startRow
          && widget.startColumn === creation.startColumn));
      if (newWidget) {
        area.widget = newWidget;
        takenIds.add(newWidget.id);
        this.reconciledSequences.set(area, sequence);
      }
    });
    this.resource.widgets = this.widgetAreas().map((area) => area.widget);
    this.publishGeometry();
  }

  private buildGridAreas() {
    const cells:GridArea[] = [];

    // the one extra row is added in case the user wants to drag a widget to the very bottom
    for (let row = 1; row <= this.numRows() + 1; row++) {
      cells.push(...this.buildGridAreasRow(row));
    }

    return cells;
  }

  private buildGridGaps() {
    const cells:GridArea[] = [];

    // special case where we want no gaps
    if (this.isSingleCell()) {
      return cells;
    }

    for (let row = 1; row <= this.numRows() + 1; row++) {
      cells.push(...this.buildGridGapRow(row));
    }

    return cells;
  }

  private buildGridAreasRow(row:number) {
    const cells:GridArea[] = [];

    for (let column = 1; column <= this.numColumns(); column++) {
      const cell = new GridArea(row,
        row + 1,
        column,
        column + 1);

      cells.push(cell);
    }

    return cells;
  }

  private buildGridGapRow(row:number) {
    const cells:GridGap[] = [];

    for (let column = 1; column <= this.numColumns(); column++) {
      cells.push(new GridGap(row,
        row + 1,
        column,
        column + 1,
        'row'));
    }

    if (row <= this.numRows()) {
      for (let column = 1; column <= this.numColumns() + 1; column++) {
        cells.push(new GridGap(row,
          row + 1,
          column,
          column + 1,
          'column'));
      }
    }

    return cells;
  }

  // persist all changes to the areas caused by dragging/resizing
  // to the widget
  public writeAreaChangesToWidgets() {
    this.widgetAreas().forEach((area) => {
      area.writeAreaChangeToWidget();
    });
  }

  public addColumn(column:number, excludeRow:number) {
    this.columnCount.update((count) => count + 1);

    const movedWidgets:GridWidgetArea[] = [];

    for (let row = 1; row <= this.numRows(); row++) {
      if (row === excludeRow) {
        continue;
      }

      const widget = this
        .rowWidgets(row)
        .sort((a, b) => a.startColumn - b.startColumn)
        .find((w) => !(w.startRow < excludeRow && w.endRow > excludeRow)
          && (w.startColumn === column + 1
            || w.endColumn === column + 1
            || (w.startColumn <= column && w.endColumn > column)));

      if (widget) {
        movedWidgets.push(widget);
        widget.endColumn++;
      }
    }

    this.moveSubsequentRowWidgets(this.widgetAreas().filter((widget) => !movedWidgets.includes(widget)),
      column);
  }

  public addRow(row:number, excludeColumn:number) {
    this.rowCount.update((count) => count + 1);

    const movedWidgets:GridWidgetArea[] = [];

    for (let column = 1; column <= this.numColumns(); column++) {
      if (column === excludeColumn) {
        continue;
      }

      const widget = this
        .columnWidgets(column)
        .sort((a, b) => a.startRow - b.startRow)
        .find((w) => !(w.startColumn < excludeColumn && w.endColumn > excludeColumn)
          && (w.startRow === row + 1
            || w.endRow === row + 1
            || (w.startRow <= row && w.endRow > row)));

      if (widget) {
        movedWidgets.push(widget);
        widget.endRow++;
      }
    }

    this.moveSubsequentColumnWidgets(this.widgetAreas().filter((widget) => !movedWidgets.includes(widget)),
      row);
  }

  public removeColumn(column:number) {
    this.columnCount.update((count) => count - 1);

    // shrink widgets that span more than the removed column
    this.widgetAreas().forEach((widget) => {
      if (widget.startColumn <= column && widget.endColumn >= column + 1) {
        // shrink widgets that span more than the removed column
        widget.endColumn--;
      }
    });

    // move all widgets that are after the removed column
    // so that they appear to keep their place.
    this.widgetAreas().filter((widget) => widget.startColumn > column).forEach((widget) => {
      widget.startColumn--;
      widget.endColumn--;
    });
  }

  public removeRow(row:number) {
    this.rowCount.update((count) => count - 1);

    // shrink widgets that span more than the removed row
    this.widgetAreas().forEach((widget) => {
      if (widget.startRow <= row && widget.endRow >= row + 1) {
        // shrink widgets that span more than the removed row
        widget.endRow--;
      }
    });

    // move all widgets that are after the removed row
    // so that they appear to keep their place.
    this.widgetAreas().filter((widget) => widget.startRow > row).forEach((widget) => {
      widget.startRow--;
      widget.endRow--;
    });
  }

  public resetAreas(ignoredArea:GridWidgetArea|null = null) {
    this.widgetAreas().filter((area) => area.guid !== ignoredArea?.guid).forEach((area) => area.reset());

    this.rowCount.set(this.resource.rowCount);
    this.columnCount.set(this.resource.columnCount);
    this.publishGeometry();
  }

  private fetchSchema(resource:GridResource) {
    this.apiV3Service.grids.id(resource).form.post({})
      .pipe(takeUntilDestroyed(this.destroyRef))
      .subscribe((form) => {
        if (this.gridResource() !== resource) {
          return;
        }
        this.schemaState.set(form.schema);
        this.$schema.next(form.schema);
      });
  }

  public removeWidget(removedWidget:GridWidgetResource):Promise<GridResource> {
    this.resource.widgets = this.resource.widgets.filter((widget) => widget !== removedWidget && (!removedWidget.id || widget.id !== removedWidget.id));
    this.widgets.update((areas) => areas.filter((area) => area.widget !== removedWidget && (!removedWidget.id || area.widget.id !== removedWidget.id)));
    this.cleanupUnusedAreas();
    return this.rebuildAndPersist();
  }

  private rowWidgets(row:number) {
    return this.widgetAreas().filter((widget) => widget.startRow === row);
  }

  private moveSubsequentRowWidgets(rowWidgets:GridWidgetArea[], column:number) {
    rowWidgets.forEach((subsequentWidget) => {
      if (subsequentWidget.startColumn > column) {
        subsequentWidget.startColumn++;
        subsequentWidget.endColumn++;
      }
    });
  }

  private columnWidgets(column:number) {
    return this.widgetAreas().filter((widget) => widget.startColumn === column);
  }

  private moveSubsequentColumnWidgets(columnWidgets:GridWidgetArea[], row:number) {
    columnWidgets.forEach((subsequentWidget) => {
      if (subsequentWidget.startRow > row) {
        subsequentWidget.startRow++;
        subsequentWidget.endRow++;
      }
    });
  }
}

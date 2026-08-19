import {
  ChangeDetectorRef, inject,
  Injectable,
  Injector,
  OnDestroy,
} from '@angular/core';
import { OpModalService } from 'core-app/shared/components/modal/modal.service';
import { AddGridWidgetModalComponent } from 'core-app/shared/components/grids/widgets/add/add.modal';
import { GridWidgetResource } from 'core-app/features/hal/resources/grid-widget-resource';
import { GridArea } from 'core-app/shared/components/grids/areas/grid-area';
import { HalResourceService } from 'core-app/features/hal/services/hal-resource.service';
import { GridWidgetArea } from 'core-app/shared/components/grids/areas/grid-widget-area';
import { GridAreaService } from 'core-app/shared/components/grids/grid/area.service';
import { GridDragAndDropService } from 'core-app/shared/components/grids/grid/drag-and-drop.service';
import { GridResizeService } from 'core-app/shared/components/grids/grid/resize.service';
import { GridMoveService } from 'core-app/shared/components/grids/grid/move.service';
import { GridGap } from 'core-app/shared/components/grids/areas/grid-gap';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { GridResource } from 'core-app/features/hal/resources/grid-resource';

@Injectable()
export class GridAddWidgetService implements OnDestroy {
  readonly opModalService = inject(OpModalService);
  readonly injector = inject(Injector);
  readonly halResource = inject(HalResourceService);
  readonly layout = inject(GridAreaService);
  readonly drag = inject(GridDragAndDropService);
  readonly move = inject(GridMoveService);
  readonly resize = inject(GridResizeService);
  readonly i18n = inject(I18nService);
  readonly cdRef = inject(ChangeDetectorRef);

  text = { add: this.i18n.t('js.grid.add_widget') };

  private boundListener = this.createNewWidget.bind(this);


  constructor() {
    document.addEventListener('overview:addWidget', this.boundListener);
  }

  ngOnDestroy():void {
    document.removeEventListener('overview:addWidget', this.boundListener);
  }

  public isAddable(area:GridArea) {
    return !this.drag.currentlyDragging
      && !this.resize.currentlyResizing
      && (this.layout.mousedOverArea === area || this.layout.isSingleCell || this.layout.inHelpMode)
      && this.isAllowed;
  }

  public widget(area:GridArea):Promise<GridWidgetResource|null> {
    return this
      .select(area)
      .then(async (widgetResource) => {
        if (this.layout.isGap(area)) {
          this.addLine(area);
        }

        const newArea = new GridWidgetArea(widgetResource);

        this.setMaxWidth(newArea);

        await this.persist(newArea);
        return widgetResource;
      })
      .catch(() => null);
  }

  public get addText() {
    return this.text.add;
  }

  private select(area:GridArea) {
    return new Promise<GridWidgetResource>((resolve, reject) => {
      this.opModalService.show(
        AddGridWidgetModalComponent,
        this.injector,
        { $schema: this.layout.$schema },
      ).subscribe((modal) => {
        modal.closingEvent.subscribe(() => {
          const registered = modal.chosenWidget;

          if (!registered) {
            reject();
            return;
          }

          const source = {
            _type: 'GridWidget',
            identifier: registered.identifier,
            startRow: area.startRow,
            endRow: area.endRow,
            startColumn: area.startColumn,
            endColumn: area.endColumn,
            options: registered.properties || {},
          };

          const resource:GridWidgetResource = this.halResource.createHalResource(source);

          resource.grid = this.layout.gridResource;

          resolve(resource);
        });
      });
    });
  }

  private addLine(area:GridGap) {
    if (area.isRow) {
      // - 1 to have it added before
      this.layout.addRow(area.startRow - 1, area.startColumn);
    } else if (area.isColumn) {
      // - 1 to have it added before
      this.layout.addColumn(area.startColumn - 1, area.startRow);
    }
  }

  // try to set it to a layout with a height of 1 and as wide as possible
  // but shrink if that is outside the grid or overlaps any other widget
  private setMaxWidth(area:GridWidgetArea) {
    area.endColumn = this.layout.numColumns + 1;

    this.layout.widgetAreas.forEach((existingArea) => {
      if (area.startColumnOverlaps(existingArea)) {
        area.endColumn = existingArea.startColumn;
      }
    });
  }

  private async persist(area:GridWidgetArea):Promise<GridResource> {
    area.writeAreaChangeToWidget();
    this.layout.widgetAreas.push(area);
    this.layout.widgetResources.push(area.widget);

    return this.layout.rebuildAndPersist();
  }

  public get isAllowed() {
    return this.layout.gridResource?.updateImmediately;
  }

  private async createNewWidget():Promise<void> {
    const newGap = new GridGap(1, 2, 1, 2, 'row');
    await this.widget(newGap);
    this.cdRef.detectChanges();
  }
}

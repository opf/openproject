import {Injectable, OnDestroy} from '@angular/core';
import {GridWidgetArea} from "core-app/modules/grids/areas/grid-widget-area";
import {GridArea} from "core-app/modules/grids/areas/grid-area";
import {GridAreaService} from "core-app/modules/grids/grid/area.service";
import {GridMoveService} from "core-app/modules/grids/grid/move.service";
import { Subscription } from 'rxjs';
import { filter, distinctUntilChanged, throttleTime } from 'rxjs/operators';

@Injectable()
export class GridDragAndDropService implements OnDestroy {
  public draggedArea:GridWidgetArea|null;
  public placeholderArea:GridWidgetArea|null;
  public draggedHeight:number|null;
  private mousedOverAreaObserver:Subscription;

  constructor(readonly layout:GridAreaService,
              readonly move:GridMoveService) {
    // ngOnInit is not called on services
    this.setupMousedOverAreaSubscription();
  }

  ngOnDestroy():void {
    this.mousedOverAreaObserver.unsubscribe();
  }

  private setupMousedOverAreaSubscription() {
    this.mousedOverAreaObserver = this
      .layout
      .$mousedOverArea
      .pipe(
        // avoid flickering of widgets as the grid gets resized by the placeholder movement
        throttleTime(10),
        distinctUntilChanged(),
        filter((area) => this.currentlyDragging && !!area && !this.layout.isGap(area) && (this.placeholderArea!.startRow !== area.startRow || this.placeholderArea!.startColumn !== area.startColumn)),
      ).subscribe(area => {
        this.updateArea(area!);

        this.layout.scrollPlaceholderIntoView();
      });
  }

  private updateArea(area:GridArea) {
    this.layout.resetAreas(this.draggedArea);
    this.moveAreasOnDragging(area);
  }

  private moveAreasOnDragging(dropArea:GridArea) {
    if (!this.placeholderArea) {
      return;
    }
    let widgetArea = this.draggedArea!;

    // Set the draggedArea's startRow/startColumn properties
    // to the drop zone ones.
    // The dragged Area should keep it's height and width normally but will
    // shrink if the area would otherwise end outside the grid.
    // we cannot use the widget's original area as moving it while dragging confuses cdkDrag
    this.copyPositionButRestrict(dropArea, this.placeholderArea);

    this.move.down(this.placeholderArea, widgetArea);
  }

  public get currentlyDragging() {
    return !!this.draggedArea;
  }

  public isDropOnlyArea(area:GridArea) {
    return !this.currentlyDragging && area.endRow === this.layout.numRows + 2;
  }

  public isDragged(area:GridWidgetArea) {
    return this.currentlyDragging && this.draggedArea!.guid === area.guid;
  }

  public isPassive(area:GridWidgetArea) {
    return this.currentlyDragging && !this.isDragged(area);
  }

  public get isDraggable() {
    return this.layout.isEditable;
  }

  public start(area:GridWidgetArea) {
    this.placeholderArea = new GridWidgetArea(area.widget);
    // TODO find an angular way to do this that ideally does not require passing the element from the grid component
    this.draggedHeight = (document as any).getElementById(area.guid).offsetHeight - 2; // border width * 2
    this.draggedArea = area;
  }

  public abort() {
    document.dispatchEvent(new Event('mouseup'));
    this.draggedArea = null;
    this.placeholderArea = null;
    this.layout.resetAreas();
  }

  public drop() {
    if (!this.draggedArea) {
      return;
    }

    this.placeholderArea!.copyDimensionsTo(this.draggedArea!)

    if (!this.draggedArea!.unchangedSize) {
      this.layout.writeAreaChangesToWidgets();
      this.layout.cleanupUnusedAreas();
      this.layout.rebuildAndPersist();
    }

    this.draggedArea = null;
    this.placeholderArea = null;
  }

  private copyPositionButRestrict(source:GridArea, sink:GridWidgetArea) {
    sink.startRow = source.startRow;

    // The first condition is aimed at the case when the user drags an element to the very last row
    // which is not reflected by the numRows.
    if (source.startRow === this.layout.numRows + 1) {
      sink.endRow = this.layout.numRows + 2;
    } else if (source.startRow + sink.widget.height > this.layout.numRows + 1) {
      sink.endRow = this.layout.numRows + 1;
    } else {
      sink.endRow = source.startRow + sink.widget.height;
    }

    sink.startColumn = source.startColumn;
    if (source.startColumn + sink.widget.width > this.layout.numColumns + 1) {
      sink.endColumn = this.layout.numColumns + 1;
    } else {
      sink.endColumn = source.startColumn + sink.widget.width;
    }
  }

}

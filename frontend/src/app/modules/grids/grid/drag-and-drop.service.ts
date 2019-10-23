import {Injectable, OnDestroy, OnInit} from '@angular/core';
import {GridWidgetArea} from "core-app/modules/grids/areas/grid-widget-area";
import {CdkDragDrop} from '@angular/cdk/drag-drop';
import {GridArea} from "core-app/modules/grids/areas/grid-area";
import {GridAreaService} from "core-app/modules/grids/grid/area.service";
import {GridMoveService} from "core-app/modules/grids/grid/move.service";
import { Subscription, interval } from 'rxjs';
import { switchMap, filter, throttle, distinctUntilChanged } from 'rxjs/operators';

@Injectable()
export class GridDragAndDropService implements OnDestroy {
  public draggedArea:GridWidgetArea|null;
  public placeholderArea:GridWidgetArea|null;
  public draggedHeight:number|null;
  private aborted = false;
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
        distinctUntilChanged(),
        filter((area) => this.currentlyDragging && !!area && !this.layout.isGap(area)),
        throttle(val => interval(10))
      ).subscribe(area => {
        this.updateArea(area!);
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

    // we cannot use the widget's original area as moving it while dragging confuses cdkDrag
    this.copyPositionButRestrict(dropArea, this.placeholderArea);

    this.move.down(this.placeholderArea, widgetArea);
  }

  public get currentlyDragging() {
    return !!this.draggedArea;
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
    this.draggedArea = area;
    this.placeholderArea = new GridWidgetArea(area.widget);
    // TODO find an angular way to do this that ideally does not require passing the element from the grid component
    this.draggedHeight = (document as any).getElementById(area.guid).offsetHeight - 2; // border width * 2
  }

  public abort() {
    document.dispatchEvent(new Event('mouseup'));
    this.aborted = true;
  }

  public stop() {
    if (!this.draggedArea) {
      return;
    }

    this.draggedArea = null;
    this.placeholderArea = null;
  }

  public drop(event:CdkDragDrop<GridArea>) {
    if (this.aborted) {
      this.aborted = false;
      return;
    }

    // this.draggedArea is already reset to null at this point
    let dropArea = event.container.data;
    let draggedArea = event.previousContainer.data as GridWidgetArea;

    // Set the draggedArea's startRow/startColumn properties
    // to the drop zone ones.
    // The dragged Area should keep it's height and width normally but will
    // shrink if the area would otherwise end outside the grid.
    this.copyPositionButRestrict(dropArea, draggedArea);

    if (draggedArea.unchangedSize) {
      return;
    }

    this.layout.writeAreaChangesToWidgets();
    this.layout.cleanupUnusedAreas();
    this.layout.rebuildAndPersist();
  }

  private copyPositionButRestrict(source:GridArea, sink:GridWidgetArea) {
    sink.startRow = source.startRow;
    if (source.startRow + sink.widget.height > this.layout.numRows + 1) {
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

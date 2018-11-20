import {Component, HostBinding, Input, InjectionToken, Inject, Output, EventEmitter} from "@angular/core";
import {GridWidgetResource} from "app/modules/hal/resources/grid-widget-resource";
import {CdkDragStart} from "@angular/cdk/drag-drop";

export abstract class AbstractWidgetComponent {
  @HostBinding('style.grid-column-start') gridColumnStart:string;
  @HostBinding('style.grid-column-end') gridColumnEnd:string;
  @HostBinding('style.grid-row-start') gridRowStart:string;
  @HostBinding('style.grid-row-end') gridRowEnd:string;

  @Input() resource:GridWidgetResource;
  @Output() cdkDragStart:EventEmitter<CdkDragStart> = new EventEmitter();

  public set widgetResource(resource:GridWidgetResource) {
    this.gridColumnStart = resource.startColumn;
    this.gridColumnEnd = resource.endColumn;
    this.gridRowStart = resource.startRow;
    this.gridRowEnd = resource.endRow;
  }

  public emitDragStart(event:CdkDragStart) {
    this.cdkDragStart.emit(event);
  }
}

import {Component, HostBinding} from "@angular/core";
import {GridWidgetResource} from "core-app/modules/hal/resources/grid-widget-resource";

export abstract class AbstractWidgetComponent {
  @HostBinding('style.grid-column-start') gridColumnStart:string;
  @HostBinding('style.grid-column-end') gridColumnEnd:string;
  @HostBinding('style.grid-row-start') gridRowStart:string;
  @HostBinding('style.grid-row-end') gridRowEnd:string;

  public set widgetResource(resource:GridWidgetResource) {
    this.gridColumnStart = resource.startColumn;
    this.gridColumnEnd = resource.endColumn;
    this.gridRowStart = resource.startRow;
    this.gridRowEnd = resource.endRow;
  }
}

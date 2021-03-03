import { Injectable } from "@angular/core";
import { GridWidgetArea } from "core-app/modules/grids/areas/grid-widget-area";
import { GridAreaService } from "core-app/modules/grids/grid/area.service";
import { GridWidgetResource } from "core-app/modules/hal/resources/grid-widget-resource";

@Injectable()
export class GridRemoveWidgetService {

  constructor(readonly layout:GridAreaService) {
  }

  public area(area:GridWidgetArea) {
    this.widget(area.widget);
  }

  public widget(widget:GridWidgetResource) {
    this.layout.removeWidget(widget);
  }

}

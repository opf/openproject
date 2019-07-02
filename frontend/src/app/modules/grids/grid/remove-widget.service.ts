import {Injectable} from "@angular/core";
import {GridWidgetArea} from "core-app/modules/grids/areas/grid-widget-area";
import {GridAreaService} from "core-app/modules/grids/grid/area.service";
import {GridWidgetResource} from "core-app/modules/hal/resources/grid-widget-resource";

@Injectable()
export class GridRemoveWidgetService {

  constructor(readonly layout:GridAreaService) {
  }

  public area(area:GridWidgetArea) {
    this.widget(area.widget);
  }

  public widget(widget:GridWidgetResource) {
    let removedWidget = widget;

    this.layout.widgetResources = this.layout.widgetResources.filter((widget) => {
      return widget.identifier !== removedWidget.identifier ||
        widget.startColumn !== removedWidget.startColumn ||
        widget.endColumn !== removedWidget.endColumn ||
        widget.startRow !== removedWidget.startRow ||
        widget.endRow !== removedWidget.endRow;
    });

    this.layout.buildAreas();
  }

}

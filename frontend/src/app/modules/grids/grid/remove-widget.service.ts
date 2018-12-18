import {Injectable} from "@angular/core";
import {GridWidgetArea} from "core-app/modules/grids/areas/grid-widget-area";
import {GridAreaService} from "core-app/modules/grids/grid/area.service";

@Injectable()
export class GridRemoveWidgetService {

  constructor(readonly layout:GridAreaService) {
  }

  public widget(area:GridWidgetArea) {
    let removedWidget = area.widget;

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

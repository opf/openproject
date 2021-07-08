import { Injectable } from '@angular/core';
import { GridWidgetArea } from 'core-app/shared/components/grids/areas/grid-widget-area';
import { GridAreaService } from 'core-app/shared/components/grids/grid/area.service';
import { GridWidgetResource } from 'core-app/features/hal/resources/grid-widget-resource';

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

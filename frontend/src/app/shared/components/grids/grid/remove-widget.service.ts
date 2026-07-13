import { ChangeDetectorRef, Injectable, inject } from '@angular/core';
import { GridWidgetArea } from 'core-app/shared/components/grids/areas/grid-widget-area';
import { GridAreaService } from 'core-app/shared/components/grids/grid/area.service';
import { GridWidgetResource } from 'core-app/features/hal/resources/grid-widget-resource';
import { GridResource } from 'core-app/features/hal/resources/grid-resource';

@Injectable()
export class GridRemoveWidgetService {
  readonly cdRef = inject(ChangeDetectorRef);
  readonly layout = inject(GridAreaService);

  public area(area:GridWidgetArea) {
    return this.widget(area.widget);
  }

  public widget(widget:GridWidgetResource):Promise<GridResource> {
    return this.layout
      .removeWidget(widget)
      .finally(() => this.cdRef.detectChanges());
  }
}

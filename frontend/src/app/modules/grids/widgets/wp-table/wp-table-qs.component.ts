import {Component} from '@angular/core';
import {AbstractWidgetComponent} from "core-app/modules/grids/widgets/abstract-widget.component";
import {GridWidgetResource} from "core-app/modules/hal/resources/grid-widget-resource";

@Component({
  templateUrl: './wp-table-qs.component.html',
  styleUrls: ['./wp-table-qs.component.sass'],
})
export class WidgetWpTableQuerySpaceComponent extends AbstractWidgetComponent {
  public onResourceChanged(resource:GridWidgetResource) {
    this.resourceChanged.emit(resource);
  }
}

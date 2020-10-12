import {Component} from '@angular/core';
import {AbstractWidgetComponent} from "core-app/modules/grids/widgets/abstract-widget.component";
import {WidgetChangeset} from "core-app/modules/grids/widgets/widget-changeset";

@Component({
  templateUrl: './wp-table-qs.component.html',
  styleUrls: ['./wp-table-qs.component.sass'],
})
export class WidgetWpTableQuerySpaceComponent extends AbstractWidgetComponent {
  public onResourceChanged(changeset:WidgetChangeset) {
    this.resourceChanged.emit(changeset);
  }
}

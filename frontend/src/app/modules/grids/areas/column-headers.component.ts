import {Component,
  Input,
  HostBinding} from "@angular/core";
import {GridComponent} from "core-app/modules/grids/grid.component";

@Component({
  templateUrl: './column-headers.component.html',
  selector: 'grid-area-column-headers'
})
export class GridAreaColumnHeadersComponent {
  @Input() grid:GridComponent;

  // array containing Numbers from 1 to this.numColumns
  public get columnNumbers() {
    return Array.from(Array(this.grid.numColumns + 1).keys()).slice(1);
  }
}

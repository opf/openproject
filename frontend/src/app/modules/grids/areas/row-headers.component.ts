import {Component,
  Input,
  HostBinding} from "@angular/core";
import {GridComponent} from "core-app/modules/grids/grid.component";

@Component({
  templateUrl: './row-headers.component.html',
  selector: 'grid-area-row-headers'
})
export class GridAreaRowHeadersComponent {
  @Input() grid:GridComponent;

  // array containing Numbers from 1 to this.numColumns
  public get rowNumbers() {
    return Array.from(Array(this.grid.numRows + 1).keys()).slice(1);
  }
}

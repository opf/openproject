import { ChangeDetectionStrategy, ChangeDetectorRef, Component, EventEmitter, Input, OnInit, Output } from "@angular/core";

export interface ITileViewEntry {
    text:string;
    attribute:string;
    icon:string;
    description:string;
    image:string;
  }

  @Component({
    selector: 'tile-view',
    styleUrls: ['./tile-view.component.sass'],
    templateUrl: './tile-view.component.html',
    changeDetection: ChangeDetectionStrategy.OnPush
  })
export class TileViewComponent {
    @Input() public tiles:ITileViewEntry[];
    @Input() public disable = false;

    @Output() public create = new EventEmitter<string>();

    public disabled() {
      return this.disable;
    }

    public created(attribute:string) {
      this.create.emit(attribute);
    }

}

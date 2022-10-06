import {
  Component,
    EventEmitter,
  HostBinding,
  Input,
  Output,
} from '@angular/core';
import SpotDropAlignmentOption from '../../../drop-alignment-options';

@Component({
  selector: 'sb-drop-modal-list',
  templateUrl: './DropModalList.component.html',
})
export class SbDropModalListComponent {
  @Input() public alignment:SpotDropAlignmentOption = SpotDropAlignmentOption.BottomLeft;

  @Input('open') public dropModalOpen = false;

  @Output('closed') public closed = new EventEmitter();

  constructor() {}

  public toggleDropModal() {
    this.dropModalOpen = !this.dropModalOpen;
  }

  close():void {
    this.dropModalOpen = false;
    this.closed.emit();
  }
}

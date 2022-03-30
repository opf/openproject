import {
  Component,
  HostBinding,
  Input,
} from '@angular/core';
import SpotDropAlignmentOption from '../../drop-alignment-options';

@Component({
  selector: 'spot-tooltip',
  templateUrl: './tooltip.component.html',
})
export class SpotTooltipComponent {
  @HostBinding('class.spot-tooltip') public className = true;

  @Input() forceShow = false;

  @Input() public alignment:SpotDropAlignmentOption = SpotDropAlignmentOption.BottomCenter;

  get alignmentClass():string {
    return `spot-tooltip--body_${this.alignment}`;
  }
}

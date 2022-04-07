import {
  Component,
  HostBinding,
  Input,
  ChangeDetectionStrategy,
} from '@angular/core';
import SpotDropAlignmentOption from '../../drop-alignment-options';

@Component({
  selector: 'spot-tooltip',
  templateUrl: './tooltip.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class SpotTooltipComponent {
  @HostBinding('class.spot-tooltip') public className = true;

  @Input() disabled = false;

  @Input() public alignment:SpotDropAlignmentOption = SpotDropAlignmentOption.BottomCenter;

  get alignmentClass():string {
    return `spot-tooltip--body_${this.alignment}`;
  }
}

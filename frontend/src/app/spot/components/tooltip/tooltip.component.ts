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
  standalone: false,
})
export class SpotTooltipComponent {
  @HostBinding('class.spot-tooltip') public className = true;

  /**
   * Show a dark-gray version of the tooltip
   */
  @Input() @HostBinding('class.spot-tooltip_dark') public dark = false;

  /**
   * Whether the tooltip should be disabled.
   * In that case, hovering the trigger element will not do anything.
   */
  @Input() public disabled = false;

  /**
   * The alignment of the tooltip. There are twelve alignments in total. You can check which ones they are
   * from the `SpotDropAlignmentOption` Enum that is available in 'core-app/spot/drop-alignment-options'.
   */
  @Input() public alignment:SpotDropAlignmentOption = SpotDropAlignmentOption.BottomCenter;

  get alignmentClass():string {
    return `spot-tooltip--body_${this.alignment}`;
  }
}

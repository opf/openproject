import {
  Component,
  Input,
  OnInit,
} from '@angular/core';
import SpotDropAlignmentOption from '../../../drop-alignment-options';

@Component({
  selector: 'sb-tooltip',
  templateUrl: './Tooltip.component.html',
})
export class SbTooltipComponent implements OnInit {
  @Input() public dark = false;

  @Input() public disabled = false;

  @Input() public alignment:SpotDropAlignmentOption = SpotDropAlignmentOption.BottomCenter;

  @Input() public body:string = '';

  get alignmentClass():string {
    return `spot-tooltip--body_${this.alignment}`;
  }

  ngOnInit() {
    console.log(this.dark, this.disabled, this.body, this.alignment);
  }
}

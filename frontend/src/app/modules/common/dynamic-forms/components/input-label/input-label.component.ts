import { Component, Input } from '@angular/core';

@Component({
  selector: 'op-input-label',
  templateUrl: './input-label.component.html',
  styleUrls: ['./input-label.component.scss']
})
export class InputLabelComponent {
  @Input()
  text:string;

  @Input()
  for:string;
}

import { Component, Input } from '@angular/core';
import { FormlyFieldConfig } from "@ngx-formly/core";

@Component({
  selector: 'op-input-label',
  templateUrl: './input-label.component.html',
  styleUrls: ['./input-label.component.scss']
})
export class InputLabelComponent {
  @Input()
  field:FormlyFieldConfig;
}

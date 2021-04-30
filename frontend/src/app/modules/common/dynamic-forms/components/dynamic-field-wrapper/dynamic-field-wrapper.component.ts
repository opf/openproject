import { Component, ChangeDetectionStrategy } from '@angular/core';
import { FieldWrapper } from "@ngx-formly/core";

@Component({
  selector: 'op-dynamic-field-wrapper',
  templateUrl: './dynamic-field-wrapper.component.html',
  styleUrls: ['./dynamic-field-wrapper.component.sass'],
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class DynamicFieldWrapperComponent extends FieldWrapper {
}

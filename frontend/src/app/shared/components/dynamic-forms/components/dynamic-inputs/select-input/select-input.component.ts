import { Component, OnInit } from '@angular/core';
import { FieldType } from '@ngx-formly/core';
import idFromLink from 'core-app/features/hal/helpers/id-from-link';

@Component({
  selector: 'op-select-input',
  templateUrl: './select-input.component.html',
  styleUrls: ['./select-input.component.scss'],
})
export class SelectInputComponent extends FieldType {
}

import { ChangeDetectionStrategy, Component, HostBinding } from '@angular/core';
import { FieldType } from '@ngx-formly/core';

@Component({
  selector: 'op-date-input',
  changeDetection: ChangeDetectionStrategy.OnPush,
  templateUrl: './date-input.component.html',
  styleUrls: ['./date-input.component.scss'],
})
export class DateInputComponent extends FieldType {
  @HostBinding('class') get class() {
    return (this.model?.id === 'projects' && this.key.toString().startsWith('customField'))
      ? 'form--date-picker-container -xslim'
      : null;
  }
}

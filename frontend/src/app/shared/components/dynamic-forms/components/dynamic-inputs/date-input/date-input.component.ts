import { ChangeDetectionStrategy, Component, OnInit } from '@angular/core';
import { FieldType } from '@ngx-formly/core';

@Component({
  selector: 'op-date-input',
  changeDetection: ChangeDetectionStrategy.OnPush,
  templateUrl: './date-input.component.html',
  styleUrls: ['./date-input.component.scss'],
})
export class DateInputComponent extends FieldType implements OnInit {
  model:IOPFormModel;

  showIgnoreNonWorkingDays = false;

  ngOnInit():void {
    // Display the "Working days only" switch to projects date custom field only.
    this.showIgnoreNonWorkingDays = this.model?.id === 'projects' && this.key.toString().startsWith('customField');
  }
}

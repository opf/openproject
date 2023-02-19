import {
  ChangeDetectionStrategy,
  Component,
} from '@angular/core';
import { FieldType } from '@ngx-formly/core';

@Component({
  selector: 'op-project-input',
  templateUrl: './project-input.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class ProjectInputComponent extends FieldType {
}

import {
  ChangeDetectionStrategy,
  Component,
  OnInit,
} from '@angular/core';
import { FieldType } from '@ngx-formly/core';

@Component({
  selector: 'op-user-input',
  templateUrl: './user-input.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class UserInputComponent extends FieldType implements OnInit {
  projectId:string|undefined;

  public ngOnInit():void {
    this.projectId = this.model?.id;
  }
}

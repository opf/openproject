import { ChangeDetectionStrategy, Component, OnInit } from '@angular/core';
import { FieldType } from '@ngx-formly/core';
import idFromLink from 'core-app/features/hal/helpers/id-from-link';

@Component({
  selector: 'op-project-input',
  templateUrl: './project-input.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class ProjectInputComponent extends FieldType implements OnInit {
  projectId:string|undefined;

  public ngOnInit():void {
    this.projectId = idFromLink(this.model?.project?.href);
  }
}

import { Component, OnInit } from '@angular/core';
import { FieldType } from '@ngx-formly/core';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';

@Component({
  selector: 'op-select-input',
  templateUrl: './select-input.component.html',
  styleUrls: ['./select-input.component.scss'],
})
export class SelectInputComponent extends FieldType implements OnInit {
  projectId:string|undefined;

  public ngOnInit():void {
    if (this.model?.project) {
      this.projectId = HalResource.idFromLink(this.model.project?.href);
    }
  }
}

import { Component } from '@angular/core';
import { FieldType } from '@ngx-formly/core';
import { projectStatusCodeCssClass } from 'core-app/shared/components/fields/helpers/project-status-helper';

@Component({
  selector: 'op-select-project-status-input',
  templateUrl: './select-project-status-input.component.html',
})
export class SelectProjectStatusInputComponent extends FieldType {
  cssClass(item:any) {
    return projectStatusCodeCssClass(item.id);
  }
}

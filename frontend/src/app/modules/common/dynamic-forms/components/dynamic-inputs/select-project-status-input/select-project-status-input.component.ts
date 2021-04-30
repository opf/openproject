import { Component } from '@angular/core';
import { FieldType } from "@ngx-formly/core";
import { projectStatusCodeCssClass, projectStatusI18n } from "core-app/modules/fields/helpers/project-status-helper";
import { Observable } from 'rxjs';
import { I18nService } from "core-app/modules/common/i18n/i18n.service";

@Component({
  selector: 'op-select-project-status-input',
  templateUrl: './select-project-status-input.component.html'
})
export class SelectProjectStatusInputComponent extends FieldType {
  constructor (
    private I18n:I18nService
  ) { super() }

  defaultValue = {
    id: 'not_set',
    name: projectStatusI18n('not_set', this.I18n),
    _links: {
      self: {
        href: null
      }
    }
  }

  // This and the ngModel is only necessary so that the
  // default value can be set if no value has been set on the model before.
  currentStatus = this.defaultValue;

  ngOnInit() {
    if (this.model._links.status !== null) {
      this.currentStatus = this.model._links.status;
    }

    (this.to.options as Observable<any>).subscribe(values => {
      values.unshift(this.defaultValue)
    })
  }

  cssClass(item:any) {
    return projectStatusCodeCssClass(item.id)
  }
}

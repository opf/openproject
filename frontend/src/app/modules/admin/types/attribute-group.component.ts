import {Component, EventEmitter, Input, Output} from '@angular/core';
import {TypeFormAttribute, TypeGroup} from "core-app/modules/admin/types/type-form-configuration.component";
import {I18nService} from "core-app/modules/common/i18n/i18n.service";

@Component({
  selector: 'type-form-attribute-group',
  templateUrl: './attribute-group.component.html'
})
export class TypeFormAttributeGroupComponent {
  @Input() public group:TypeGroup;
  @Output() public deleteGroup = new EventEmitter<void>();

  text = {
    custom_field: this.I18n.t('js.admin.type_form.custom_field')
  };

  constructor(private I18n:I18nService) {
  }

  rename(newValue:string) {
    this.group.name = newValue;
  }

  removeAttribute(attribute:TypeFormAttribute) {
    this.group = {
      ...this.group,
      attributes: this.group.attributes.filter(a => a !== attribute)
    };
  }
}

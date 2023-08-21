import {
  ChangeDetectionStrategy, ChangeDetectorRef, Component, EventEmitter, Input, Output,
} from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { TypeFormAttribute, TypeGroup } from 'core-app/features/admin/types/type-form-configuration.component';

@Component({
  selector: 'op-type-form-attribute-group',
  changeDetection: ChangeDetectionStrategy.OnPush,
  templateUrl: './attribute-group.component.html',
})
export class TypeFormAttributeGroupComponent {
  @Input() public group:TypeGroup;

  @Output() public deleteGroup = new EventEmitter<void>();

  @Output() public removeAttribute = new EventEmitter<TypeFormAttribute>();

  text = {
    custom_field: this.I18n.t('js.admin.type_form.custom_field'),
  };

  constructor(private I18n:I18nService,
    private cdRef:ChangeDetectorRef) {
  }

  rename(newValue:string) {
    this.group.name = newValue;
    delete this.group.key;
    this.cdRef.detectChanges();
  }

  removeFromGroup(attribute:TypeFormAttribute) {
    this.group.attributes = this.group.attributes.filter((a) => a !== attribute);
    this.removeAttribute.emit(attribute);
  }
}

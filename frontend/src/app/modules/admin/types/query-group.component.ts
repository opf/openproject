import {Component, EventEmitter, Input, Output} from '@angular/core';
import {I18nService} from "core-app/modules/common/i18n/i18n.service";

@Component({
  selector: 'type-form-query-group',
  templateUrl: './query-group.component.html'
})
export class TypeFormQueryGroupComponent {

  text = {
    edit_query: this.I18n.t('js.form_configuration.edit_query')
  };

  @Input() public group:any;
  @Output() public deleteGroup = new EventEmitter<void>();

  constructor(readonly I18n:I18nService) {
  }

  rename(newValue:string) {
    this.group.name = newValue;
  }
}

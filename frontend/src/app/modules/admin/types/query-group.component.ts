import {ChangeDetectionStrategy, ChangeDetectorRef, Component, EventEmitter, Input, Output} from '@angular/core';
import {I18nService} from "core-app/modules/common/i18n/i18n.service";

@Component({
  selector: 'type-form-query-group',
  changeDetection: ChangeDetectionStrategy.OnPush,
  templateUrl: './query-group.component.html'
})
export class TypeFormQueryGroupComponent {

  text = {
    edit_query: this.I18n.t('js.admin.type_form.edit_query')
  };

  @Input() public group:any;
  @Output() public editQuery = new EventEmitter<void>();
  @Output() public deleteGroup = new EventEmitter<void>();

  constructor(private I18n:I18nService,
              private cdRef:ChangeDetectorRef) {
  }

  rename(newValue:string) {
    this.group.name = newValue;
    this.cdRef.detectChanges();
  }
}

import {
  ChangeDetectionStrategy, ChangeDetectorRef, Component, EventEmitter, Input, Output,
} from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { TypeGroup } from 'core-app/features/admin/types/type-form-configuration.component';

@Component({
  selector: 'op-type-form-query-group',
  changeDetection: ChangeDetectionStrategy.OnPush,
  templateUrl: './query-group.component.html',
})
export class TypeFormQueryGroupComponent {
  text = {
    edit_query: this.I18n.t('js.admin.type_form.edit_query'),
  };

  @Input() public group:TypeGroup;

  @Output() public editQuery = new EventEmitter<void>();

  @Output() public deleteGroup = new EventEmitter<void>();

  constructor(private I18n:I18nService,
    private cdRef:ChangeDetectorRef) {
  }

  rename(newValue:string):void {
    this.group.name = newValue;
    this.cdRef.detectChanges();
  }
}

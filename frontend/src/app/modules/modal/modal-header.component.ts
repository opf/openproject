import {
  Component,
  EventEmitter,
  Input,
  Output,
  HostBinding,
} from '@angular/core';
import { I18nService } from "core-app/modules/common/i18n/i18n.service";

@Component({
  selector: 'op-modal-header',
  templateUrl: './modal-header.component.html',
})
export class OpModalHeaderComponent {
  @HostBinding('class.op-modal--header') className = true;
  @Input() icon = '';
  @Output('close') close = new EventEmitter<void>();

  public text = {
    closePopup: this.I18n.t('js.close_popup_title'),
  };

  constructor(
    readonly I18n:I18nService,
  ) {}
}

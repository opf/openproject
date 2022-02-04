import {
  Component, EventEmitter, HostBinding, Output,
} from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';

@Component({
  selector: 'op-modal-heading',
  templateUrl: './modal-heading.component.html',
})
export class OpModalHeadingComponent {
  @HostBinding('class.op-modal--heading') className = true;

  @Output('close') close = new EventEmitter<void>();

  public text = {
    closePopup: this.I18n.t('js.close_popup_title'),
  };

  constructor(
    readonly I18n:I18nService,
  ) {}
}

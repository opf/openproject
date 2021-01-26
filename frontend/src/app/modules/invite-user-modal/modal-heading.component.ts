import {
  Component,
  EventEmitter,
  Output,
  HostBinding,
} from '@angular/core';
import {I18nService} from "core-app/modules/common/i18n/i18n.service";

@Component({
  selector: 'op-ium-modal-heading',
  templateUrl: './modal-heading.component.html',
  styleUrls: ['./modal-heading.component.sass'],
})
export class ModalHeadingComponent {
  @HostBinding('class.op-modal-heading--close-button') className = true;
  @Output('close') close = new EventEmitter<void>();

  public text = {
    closePopup: this.I18n.t('js.close_popup_title'),
  };

  constructor(
    readonly I18n:I18nService,
  ) {}
}

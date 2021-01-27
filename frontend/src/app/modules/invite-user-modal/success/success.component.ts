import {
  Component,
  Input,
  EventEmitter,
  Output,
  ElementRef,
} from '@angular/core';
import {I18nService} from "core-app/modules/common/i18n/i18n.service";

@Component({
  selector: 'op-ium-success',
  templateUrl: './success.component.html',
  styleUrls: ['./success.component.sass'],
})
export class SuccessComponent {
  @Input() principal:any = null;
  @Input() project:any = null;
  @Input() type:any = null;

  @Output('close') close = new EventEmitter<void>();

  public get text() {
    return {
      title: this.I18n.t('js.invite_user_modal.success.title', {
        type: this.type,
        project: this.project,
        principal: this.principal,
      }),
      description: this.I18n.t('js.invite_user_modal.success.description', {
        type: this.type,
        project: this.project,
        principal: this.principal,
      }),
      nextButton: this.I18n.t('js.invite_user_modal.success.next_button'),
    };
  }

  constructor(
    readonly I18n:I18nService,
    readonly elementRef:ElementRef,
  ) {}
}

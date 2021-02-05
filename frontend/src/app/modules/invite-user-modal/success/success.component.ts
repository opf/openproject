import {
  Component,
  Input,
  EventEmitter,
  Output,
  ElementRef,
} from '@angular/core';
import {I18nService} from "core-app/modules/common/i18n/i18n.service";
import {PrincipalType} from '../invite-user.component';

@Component({
  selector: 'op-ium-success',
  templateUrl: './success.component.html',
  styleUrls: ['./success.component.sass'],
})
export class SuccessComponent {
  @Input() principal:any = null;
  @Input() project:any = null;
  @Input() type:PrincipalType;

  @Output() close = new EventEmitter<void>();

  public text = {
    title: () => this.I18n.t('js.invite_user_modal.success.title', {
      principal: this.principal.name,
    }),
    description: {
      user: () => this.I18n.t('js.invite_user_modal.success.description.user', { project: this.project?.name }),
      placeholder: () => this.I18n.t('js.invite_user_modal.success.description.placeholder', { project: this.project?.name }),
      group: () => this.I18n.t('js.invite_user_modal.success.description.group', { project: this.project?.name }),
    },
    nextButton: this.I18n.t('js.invite_user_modal.success.next_button'),
  };

  constructor(
    readonly I18n:I18nService,
    readonly elementRef:ElementRef,
  ) {}
}

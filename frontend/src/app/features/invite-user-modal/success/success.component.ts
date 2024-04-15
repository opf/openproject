import {
  Component,
  Input,
  EventEmitter,
  Output,
  ElementRef,
  ChangeDetectionStrategy,
} from '@angular/core';

import { I18nService } from 'core-app/core/i18n/i18n.service';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { ProjectResource } from 'core-app/features/hal/resources/project-resource';
import { imagePath } from 'core-app/shared/helpers/images/path-helper';
import { PrincipalType } from '../invite-user.component';

@Component({
  selector: 'op-ium-success',
  templateUrl: './success.component.html',
  styleUrls: ['./success.component.sass'],
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class SuccessComponent {
  @Input() principal:HalResource;

  @Input() project:ProjectResource;

  @Input() type:PrincipalType;

  @Input() createdNewPrincipal:boolean;

  @Output() close = new EventEmitter<void>();

  public PrincipalType = PrincipalType;

  user_image = imagePath('invite-user-modal/successful-invite.svg');

  placeholder_image = imagePath('invite-user-modal/placeholder-added.svg');

  public text = {
    title: () => this.I18n.t('js.invite_user_modal.success.title', {
      principal: this.createdNewPrincipal ? this.principal.email : this.principal.name,
    }),
    description: {
      User: () => this.I18n.t('js.invite_user_modal.success.description.user', { project: this.project?.name }),
      PlaceholderUser: () => this.I18n.t('js.invite_user_modal.success.description.placeholder', { project: this.project?.name }),
      Group: () => this.I18n.t('js.invite_user_modal.success.description.group', { project: this.project?.name }),
    },
    nextButton: this.I18n.t('js.invite_user_modal.success.next_button'),
  };

  constructor(
    readonly I18n:I18nService,
    readonly elementRef:ElementRef,
  ) {}
}

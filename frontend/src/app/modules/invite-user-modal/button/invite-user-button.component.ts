import { ChangeDetectorRef, Component } from '@angular/core';
import { NgSelectComponent } from "@ng-select/ng-select";
import { I18nService } from "core-app/modules/common/i18n/i18n.service";
import { CurrentUserService } from "core-app/modules/current-user/current-user.service";
import { CurrentProjectService } from "core-app/components/projects/current-project.service";
import { OpInviteUserModalService } from "core-app/modules/invite-user-modal/invite-user-modal.service";

@Component({
  selector: 'op-invite-user-button',
  templateUrl: './invite-user-button.component.html',
  styleUrls: ['./invite-user-button.component.sass']
})
export class InviteUserButtonComponent {
  /** This component does not provide an output, because both primary usecases were in places where the button was
   * destroyed before the modal closed, causing the data from the modal to never arrive at the parent.
   * If you want to do something with the output from the modal that is opened, use the OpInviteUserModalService
   * and subscribe to the `close` event there. 
   */
  text = {
    button: this.I18n.t('js.invite_user_modal.invite'),
  };

  canInviteUsersToProject$ = this.currentUserService.hasCapabilities$(
    'memberships/create',
    this.currentProjectService.id || undefined,
  );

  constructor(
    readonly I18n:I18nService,
    readonly opInviteUserModalService:OpInviteUserModalService,
    readonly currentUserService:CurrentUserService,
    readonly currentProjectService:CurrentProjectService,
    readonly ngSelectComponent:NgSelectComponent,
    readonly changeDetectorRef:ChangeDetectorRef,
  ) {}

  onAddNewClick($event:Event) {
    $event.stopPropagation();
    this.opInviteUserModalService.open();
    this.ngSelectComponent.close();
  }
}

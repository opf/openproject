import { ChangeDetectorRef, Component, Input } from '@angular/core';
import { NgSelectComponent } from "@ng-select/ng-select";
import { I18nService } from "core-app/modules/common/i18n/i18n.service";
import { CurrentUserService } from "core-app/modules/current-user/current-user.service";
import { OpInviteUserModalService } from "core-app/modules/invite-user-modal/invite-user-modal.service";
import { Observable } from "rxjs";
import { CurrentProjectService } from "core-components/projects/current-project.service";

@Component({
  selector: 'op-invite-user-button',
  templateUrl: './invite-user-button.component.html',
  styleUrls: ['./invite-user-button.component.sass']
})
export class InviteUserButtonComponent {
  @Input() projectId:string|null;
  /** This component does not provide an output, because both primary usecases were in places where the button was
   * destroyed before the modal closed, causing the data from the modal to never arrive at the parent.
   * If you want to do something with the output from the modal that is opened, use the OpInviteUserModalService
   * and subscribe to the `close` event there.
   */
  text = {
    button: this.I18n.t('js.invite_user_modal.invite'),
  };

  canInviteUsersToProject$:Observable<boolean>;

  constructor(
    readonly I18n:I18nService,
    readonly opInviteUserModalService:OpInviteUserModalService,
    readonly currentProjectService:CurrentProjectService,
    readonly currentUserService:CurrentUserService,
    readonly ngSelectComponent:NgSelectComponent,
    readonly changeDetectorRef:ChangeDetectorRef,
  ) {
  }

  public ngOnInit():void {
    this.projectId = this.projectId || this.currentProjectService.id;
    this.canInviteUsersToProject$ = this.currentUserService.hasCapabilities$(
      'memberships/create',
      this.projectId || undefined
    );
  }

  public onAddNewClick($event:Event):void {
    $event.stopPropagation();
    this.opInviteUserModalService.open(this.projectId);
    this.ngSelectComponent.close();
  }
}

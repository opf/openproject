import { ChangeDetectorRef, Component, OnInit } from '@angular/core';
import { NgSelectComponent } from "@ng-select/ng-select";
import { I18nService } from "core-app/modules/common/i18n/i18n.service";
import { PermissionsService } from "core-app/core/permissions/permissions.service";
import { OpInviteUserModalService } from "core-app/features/invite-user-modal/invite-user-modal.service";

@Component({
  selector: 'op-invite-user-button',
  templateUrl: './invite-user-button.component.html',
  styleUrls: ['./invite-user-button.component.sass']
})
export class InviteUserButtonComponent implements OnInit {
  /** This component does not provide an output, because both primary usecases were in places where the button was
   * destroyed before the modal closed, causing the data from the modal to never arrive at the parent.
   * If you want to do something with the output from the modal that is opened, use the OpInviteUserModalService
   * and subscribe to the `close` event there. 
   */
  text = {
    button: this.I18n.t('js.invite_user_modal.invite'),
  };
  canInviteUsersToProject:boolean;

  constructor(
    readonly I18n:I18nService,
    readonly opInviteUserModalService:OpInviteUserModalService,
    readonly permissionsService:PermissionsService,
    readonly ngSelectComponent:NgSelectComponent,
    readonly changeDetectorRef:ChangeDetectorRef,
  ) {}

  ngOnInit():void {
    this.permissionsService
      .canInviteUsersToProject()
      .subscribe(canInviteUsersToProject => {
        this.canInviteUsersToProject = canInviteUsersToProject;
        this.changeDetectorRef.detectChanges();
      });
  }

  onAddNewClick($event:Event) {
    $event.stopPropagation();
    this.opInviteUserModalService.open();
    this.ngSelectComponent.close();
  }
}

import { Component, Inject, OnInit, Optional } from '@angular/core';
import { NgSelectComponent } from "@ng-select/ng-select";
import { OpEditingPortalSchemaToken } from "core-app/modules/fields/edit/edit-field.component";
import { IFieldSchema } from "core-app/modules/fields/field.base";
import { SelectEditFieldComponent } from "core-app/modules/fields/edit/field-types/select-edit-field/select-edit-field.component";
import { MultiSelectEditFieldComponent } from "core-app/modules/fields/edit/field-types/multi-select-edit-field.component";
import { I18nService } from "core-app/modules/common/i18n/i18n.service";
import { PermissionsService } from "core-app/core/services/permissions/permissions.service";
import { OpInviteUserModalService } from "core-app/modules/invite-user-modal/invite-user-modal.service";

@Component({
  selector: 'op-invite-user-button',
  templateUrl: './invite-user-button.component.html',
  styleUrls: ['./invite-user-button.component.sass']
})
export class InviteUserButtonComponent implements OnInit {
  /* This component does not provide an output, because both primary usecases were in places where the button was
   * destroyed before the modal closed, causing the data from the modal to never arrive at the parent.
   * If you want to do something with the output from the modal that is opened, use the OpInviteUserModalService
   * and subscribe to the `close` event there. 
   */

  get showButton() {
    const showButton = this.schema?.type === 'User' &&
      this.canInviteUsersToProject &&
      (this.selectEditFieldComponent || this.multiSelectEditFieldComponent);

    return showButton;
  }
  get parentIsMultiSelectEditFieldComponent() {
    return !!this.multiSelectEditFieldComponent;
  }

  text = {
    button: this.I18n.t('js.invite_user_modal.invite'),
  };
  canInviteUsersToProject:boolean;

  constructor(
    readonly I18n:I18nService,
    readonly opInviteUserModalService:OpInviteUserModalService,
    readonly permissionsService:PermissionsService,
    readonly ngSelectComponent:NgSelectComponent,
    @Optional() readonly selectEditFieldComponent:SelectEditFieldComponent,
    @Optional() readonly multiSelectEditFieldComponent:MultiSelectEditFieldComponent,
    @Inject(OpEditingPortalSchemaToken) public schema:IFieldSchema,
  ) {}

  ngOnInit():void {
    this.permissionsService
      .canInviteUsersToProject()
      .subscribe(canInviteUsersToProject => this.canInviteUsersToProject = canInviteUsersToProject);
  }

  onAddNewClick($event:Event) {
    $event.stopPropagation();
    this.opInviteUserModalService.open();
    this.ngSelectComponent.close();
  }
}

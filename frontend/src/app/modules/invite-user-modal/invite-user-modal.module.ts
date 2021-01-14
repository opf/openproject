import {NgModule} from "@angular/core";
import {InviteUserModalComponent} from "./invite-user.component";
import {InviteProjectSelectionComponent} from "./project-selection.component";
import {InviteUserComponent} from "./user.component";
import {InviteGroupComponent} from "./group.component";
import {InvitePlaceholderComponent} from "./placeholder.component";
import {InviteRoleComponent} from "./role.component";
import {InviteMessageComponent} from "./message.component";
import {InviteSuccessComponent} from "./success.component";
import {InviteSummaryComponent} from "./summary.component";
import {NgSelectModule} from "@ng-select/ng-select";
import {OpenprojectCommonModule} from "core-app/modules/common/openproject-common.module";

@NgModule({
  imports: [
    OpenprojectCommonModule,
    NgSelectModule
  ],
  exports: [  ],
  declarations: [
    InviteUserModalComponent,
    InviteProjectSelectionComponent,
    InviteUserComponent,
    InviteGroupComponent,
    InvitePlaceholderComponent,
    InviteRoleComponent,
    InviteMessageComponent,
    InviteSuccessComponent,
    InviteSummaryComponent,
  ]
})
export class OpenprojectInviteUserModalModule { }

import {NgModule} from "@angular/core";
import {ReactiveFormsModule} from "@angular/forms";
import {InviteUserModalComponent} from "./invite-user.component";
import {InviteProjectSelectionComponent} from "./project-selection.component";
import {InviteProjectSearchComponent} from "./project-search.component";
import {InvitePrincipalComponent} from "./principal.component";
import {InvitePrincipalSearchComponent} from "./principal-search.component";
import {InviteRoleComponent} from "./role.component";
import {InviteMessageComponent} from "./message.component";
import {InviteSuccessComponent} from "./success.component";
import {InviteSummaryComponent} from "./summary.component";
import {NgSelectModule} from "@ng-select/ng-select";
import {OpenprojectCommonModule} from "core-app/modules/common/openproject-common.module";

@NgModule({
  imports: [
    OpenprojectCommonModule,
    NgSelectModule,
    ReactiveFormsModule,
  ],
  exports: [],
  declarations: [
    InviteUserModalComponent,
    InviteProjectSelectionComponent,
    InviteProjectSearchComponent,
    InvitePrincipalComponent,
    InvitePrincipalSearchComponent,
    InviteRoleComponent,
    InviteMessageComponent,
    InviteSuccessComponent,
    InviteSummaryComponent,
  ]
})
export class OpenprojectInviteUserModalModule { }

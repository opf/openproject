import { NgModule } from "@angular/core";
import { ReactiveFormsModule } from "@angular/forms";
import { OpenprojectModalModule } from "core-app/modules/modal/modal.module";
import { InviteUserModalComponent } from "./invite-user.component";
import { ProjectSelectionComponent } from "./project-selection/project-selection.component";
import { ProjectSearchComponent } from "./project-selection/project-search.component";
import { PrincipalComponent } from "./principal/principal.component";
import { PrincipalSearchComponent } from "./principal/principal-search.component";
import { RoleComponent } from "./role/role.component";
import { RoleSearchComponent } from "./role/role-search.component";
import { MessageComponent } from "./message/message.component";
import { SummaryComponent } from "./summary/summary.component";
import { SuccessComponent } from "./success/success.component";
import { NgSelectModule } from "@ng-select/ng-select";
import { OpenprojectCommonModule } from "core-app/modules/common/openproject-common.module";
import { InviteUserButtonComponent } from "core-app/modules/invite-user-modal/button/invite-user-button.component";

@NgModule({
  imports: [
    OpenprojectCommonModule,
    OpenprojectModalModule,
    NgSelectModule,
    ReactiveFormsModule,
  ],
  exports: [
    InviteUserButtonComponent,
  ],
  declarations: [
    InviteUserModalComponent,
    InviteUserButtonComponent,
    ProjectSelectionComponent,
    ProjectSearchComponent,
    PrincipalComponent,
    PrincipalSearchComponent,
    RoleComponent,
    RoleSearchComponent,
    MessageComponent,
    SuccessComponent,
    SummaryComponent,
  ]
})
export class OpenprojectInviteUserModalModule { }

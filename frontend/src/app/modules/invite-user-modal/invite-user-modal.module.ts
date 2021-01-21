import {NgModule} from "@angular/core";
import {ReactiveFormsModule} from "@angular/forms";
import {InviteUserModalComponent} from "./invite-user.component";
import {ProjectSelectionComponent} from "./project-selection/project-selection.component";
import {ProjectSearchComponent} from "./project-selection/project-search.component";
import {PrincipalComponent} from "./principal/principal.component";
import {PrincipalSearchComponent} from "./principal/principal-search.component";
import {RoleComponent} from "./role/role.component";
import {RoleSearchComponent} from "./role/role-search.component";
import {MessageComponent} from "./message/message.component";
import {SuccessComponent} from "./success/success.component";
import {SummaryComponent} from "./summary/summary.component";
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

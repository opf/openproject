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
import {SummaryComponent} from "./summary/summary.component";
import {SuccessComponent} from "./success/success.component";
import {NgSelectModule} from "@ng-select/ng-select";
import {OpenprojectModalHeadingModule} from "core-app/modules/common/modal/modal-heading.module";
import {CommonModule} from "@angular/common";
import {OpFormFieldModule} from "core-app/modules/common/form-field/op-form-field.module";
import {OptionListModule} from "core-app/modules/common/option-list/option-list.module";
import {InviteUserButtonComponent} from "core-app/modules/common/invite-user-modal/button/invite-user-button.component";
import {OpIconModule} from "core-app/modules/common/icon/icon.module";

@NgModule({
  imports: [
    CommonModule,
    OpenprojectModalHeadingModule,
    NgSelectModule,
    ReactiveFormsModule,
    OpFormFieldModule,
    OptionListModule,
    OpIconModule,
  ],
  exports: [
    InviteUserButtonComponent,
  ],
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
    InviteUserButtonComponent,
  ]
})
export class OpInviteUserModalModule { }

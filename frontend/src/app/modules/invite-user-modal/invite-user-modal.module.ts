import { APP_INITIALIZER, Injector, NgModule } from "@angular/core";
import { ReactiveFormsModule } from "@angular/forms";
import { TextFieldModule } from '@angular/cdk/text-field'; 
import { NgSelectModule } from "@ng-select/ng-select";
import { OpenprojectModalModule } from "core-app/modules/modal/modal.module";
import { OpenprojectCommonModule } from "core-app/modules/common/openproject-common.module";
import { InviteUserButtonComponent } from "core-app/modules/invite-user-modal/button/invite-user-button.component";
import { OpInviteUserModalAugmentService } from "core-app/modules/invite-user-modal/invite-user-modal-augment.service";
import { OpInviteUserModalService } from "core-app/modules/invite-user-modal/invite-user-modal.service";
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

export function initializeServices(injector:Injector) {
  return function () {
    const inviteUserAugmentService = injector.get(OpInviteUserModalAugmentService);
    inviteUserAugmentService.setupListener();
  }
}

@NgModule({
  imports: [
    OpenprojectCommonModule,
    OpenprojectModalModule,
    NgSelectModule,
    ReactiveFormsModule,
    TextFieldModule,
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
  ],
  providers: [
    OpInviteUserModalService,
    { provide: APP_INITIALIZER, useFactory: initializeServices, deps: [Injector], multi: true },
  ],
})
export class OpenprojectInviteUserModalModule {
}

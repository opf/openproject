import { APP_INITIALIZER, Injector, NgModule } from '@angular/core';
import {
  FormsModule,
  ReactiveFormsModule,
} from '@angular/forms';
import { CommonModule } from '@angular/common';
import { TextFieldModule } from '@angular/cdk/text-field';
import { NgSelectModule } from '@ng-select/ng-select';
import { CurrentUserModule } from 'core-app/core/current-user/current-user.module';
import { OpenprojectModalModule } from 'core-app/shared/components/modal/modal.module';
import { InviteUserButtonModule } from 'core-app/features/invite-user-modal/button/invite-user-button.module';
import { DynamicFormsModule } from 'core-app/shared/components/dynamic-forms/dynamic-forms.module';
import { OpInviteUserModalAugmentService } from 'core-app/features/invite-user-modal/invite-user-modal-augment.service';
import { OpSharedModule } from 'core-app/shared/shared.module';
import { OpInviteUserModalService } from 'core-app/features/invite-user-modal/invite-user-modal.service';
import { InviteUserModalComponent } from './invite-user.component';
import { ProjectSelectionComponent } from './project-selection/project-selection.component';
import { PrincipalComponent } from './principal/principal.component';
import { PrincipalSearchComponent } from './principal/principal-search.component';
import { RoleSearchComponent } from './role/role-search.component';
import { SummaryComponent } from './summary/summary.component';
import { SuccessComponent } from './success/success.component';

export function initializeServices(injector:Injector) {
  return function () {
    const inviteUserAugmentService = injector.get(OpInviteUserModalAugmentService);
    inviteUserAugmentService.setupListener();
  };
}

@NgModule({
  imports: [
    CommonModule,
    OpSharedModule,
    OpenprojectModalModule,
    FormsModule,
    NgSelectModule,
    ReactiveFormsModule,
    TextFieldModule,
    DynamicFormsModule,
    InviteUserButtonModule,
    CurrentUserModule,
  ],
  exports: [
    InviteUserButtonModule,
  ],
  declarations: [
    InviteUserModalComponent,
    ProjectSelectionComponent,
    PrincipalComponent,
    PrincipalSearchComponent,
    RoleSearchComponent,
    SuccessComponent,
    SummaryComponent,
  ],
  providers: [
    OpInviteUserModalService,
    {
      provide: APP_INITIALIZER, useFactory: initializeServices, deps: [Injector], multi: true,
    },
  ],
})
export class OpenprojectInviteUserModalModule {
}

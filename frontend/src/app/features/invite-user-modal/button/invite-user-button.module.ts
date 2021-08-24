import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { InviteUserButtonComponent } from 'core-app/features/invite-user-modal/button/invite-user-button.component';
import { IconModule } from 'core-app/shared/components/icon/icon.module';

@NgModule({
  declarations: [
    InviteUserButtonComponent,
  ],
  imports: [
    CommonModule,
    IconModule,
  ],
  exports: [
    InviteUserButtonComponent,
  ],
})
export class InviteUserButtonModule { }

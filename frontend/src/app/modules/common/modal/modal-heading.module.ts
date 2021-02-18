import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import {OpModalHeadingComponent} from "core-app/modules/common/modal/modal-heading.component";
import {OpInviteUserModalModule} from "core-app/modules/common/invite-user-modal/op-invite-user-modal.module";



@NgModule({
  declarations: [
    OpModalHeadingComponent,
  ],
  imports: [
    CommonModule
  ],
  exports: [
    OpModalHeadingComponent,
  ]
})
export class OpenprojectModalHeadingModule { }

import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { InviteUserWizardComponent } from './component/invite-user-wizard.component';
import {ReactiveFormsModule} from "@angular/forms";
import {NgSelectModule} from "@ng-select/ng-select";
import {NgOptionHighlightModule} from "@ng-select/ng-option-highlight";

@NgModule({
  declarations: [InviteUserWizardComponent],
  imports: [
    CommonModule,
    ReactiveFormsModule,
    NgSelectModule,
    NgOptionHighlightModule,
  ],
  exports: [InviteUserWizardComponent]
})
export class InviteUserWizardModule { }

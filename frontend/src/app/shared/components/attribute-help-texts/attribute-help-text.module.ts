import { NgModule } from "@angular/core";
import { CommonModule } from "@angular/common";
import { OpenprojectModalModule } from "core-app/shared/components/modal/modal.module";
import { OpenprojectAttachmentsModule } from "core-app/shared/components/attachments/openproject-attachments.module";
import { OpenprojectAccessibilityModule } from "core-app/shared/directives/a11y/openproject-a11y.module";
import { IconModule } from "core-app/shared/components/icon/icon.module";

import { AttributeHelpTextComponent } from "./attribute-help-text.component";
import { AttributeHelpTextModal } from "./attribute-help-text.modal";

@NgModule({
  imports: [
    CommonModule,
    OpenprojectModalModule,
    OpenprojectAttachmentsModule,
    OpenprojectAccessibilityModule,
    IconModule,
  ],
  declarations: [
    AttributeHelpTextComponent,
    AttributeHelpTextModal,
  ],
  providers: [
  ],
  exports: [
    AttributeHelpTextComponent,
  ]
})
export class AttributeHelpTextModule {}

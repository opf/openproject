import { CommonModule } from '@angular/common';
import { NgModule } from '@angular/core';
import { OpenprojectAttachmentsModule } from 'core-app/shared/components/attachments/openproject-attachments.module';
import { IconModule } from 'core-app/shared/components/icon/icon.module';
import { OpenprojectModalModule } from 'core-app/shared/components/modal/modal.module';

import { AttributeHelpTextComponent } from './attribute-help-text.component';
import { AttributeHelpTextModalComponent } from './attribute-help-text.modal';
import { StaticAttributeHelpTextComponent } from './static-attribute-help-text.component';
import { StaticAttributeHelpTextModalComponent } from './static-attribute-help-text.modal';

@NgModule({
  imports: [
    CommonModule,
    OpenprojectModalModule,
    OpenprojectAttachmentsModule,
    IconModule,
  ],
  declarations: [
    AttributeHelpTextComponent,
    AttributeHelpTextModalComponent,
    StaticAttributeHelpTextComponent,
    StaticAttributeHelpTextModalComponent,
  ],
  providers: [
  ],
  exports: [
    AttributeHelpTextComponent,
    StaticAttributeHelpTextComponent,
  ],
})
export class AttributeHelpTextModule {}

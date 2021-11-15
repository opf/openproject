import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { OpenprojectModalModule } from 'core-app/shared/components/modal/modal.module';
import { OpenprojectAttachmentsModule } from 'core-app/shared/components/attachments/openproject-attachments.module';
import { IconModule } from 'core-app/shared/components/icon/icon.module';

import { AttributeHelpTextComponent } from './attribute-help-text.component';
import { AttributeHelpTextModalComponent } from './attribute-help-text.modal';

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
  ],
  providers: [
  ],
  exports: [
    AttributeHelpTextComponent,
  ],
})
export class AttributeHelpTextModule {}

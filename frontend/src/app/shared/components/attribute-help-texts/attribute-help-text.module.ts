import { CommonModule } from '@angular/common';
import { CUSTOM_ELEMENTS_SCHEMA, NgModule } from '@angular/core';
import { OpenprojectAttachmentsModule } from 'core-app/shared/components/attachments/openproject-attachments.module';
import { IconModule } from 'core-app/shared/components/icon/icon.module';

import { AttributeHelpTextComponent } from './attribute-help-text.component';
import { StaticAttributeHelpTextComponent } from './static-attribute-help-text.component';
import { StaticAttributeHelpTextModalComponent } from './static-attribute-help-text.modal';

@NgModule({
  imports: [
    CommonModule,
    OpenprojectAttachmentsModule,
    IconModule,
  ],
  declarations: [
    AttributeHelpTextComponent,
    StaticAttributeHelpTextComponent,
    StaticAttributeHelpTextModalComponent,
  ],
  providers: [
  ],
  exports: [
    AttributeHelpTextComponent,
    StaticAttributeHelpTextComponent,
  ],
  schemas: [CUSTOM_ELEMENTS_SCHEMA],
})
export class AttributeHelpTextModule {}

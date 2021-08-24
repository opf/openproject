import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormattableEditFieldComponent } from 'core-app/shared/components/fields/edit/field-types/formattable-edit-field/formattable-edit-field.component';
import { OpenprojectEditorModule } from 'core-app/shared/components/editor/openproject-editor.module';
import { EditFieldControlsModule } from 'core-app/shared/components/fields/edit/field-controls/edit-field-controls.module';

@NgModule({
  declarations: [
    FormattableEditFieldComponent,
  ],
  imports: [
    CommonModule,
    OpenprojectEditorModule,
    EditFieldControlsModule,
  ],
  exports: [
    FormattableEditFieldComponent,
  ],
})
export class FormattableEditFieldModule { }

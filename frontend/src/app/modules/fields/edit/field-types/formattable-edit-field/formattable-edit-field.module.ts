import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormattableEditFieldComponent } from "core-app/modules/fields/edit/field-types/formattable-edit-field/formattable-edit-field.component";
import { OpenprojectEditorModule } from "core-app/modules/editor/openproject-editor.module";
import { EditFieldControlsModule } from "core-app/modules/fields/edit/field-controls/edit-field-controls.module";


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
  ]
})
export class FormattableEditFieldModule { }

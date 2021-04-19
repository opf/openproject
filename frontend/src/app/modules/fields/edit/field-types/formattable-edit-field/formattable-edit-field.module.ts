import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormattableEditFieldComponent } from "core-app/modules/fields/edit/field-types/formattable-edit-field/formattable-edit-field.component";
import { OpenprojectEditorModule } from "core-app/modules/editor/openproject-editor.module";


@NgModule({
  declarations: [
    FormattableEditFieldComponent,
  ],
  imports: [
    CommonModule,
    OpenprojectEditorModule,
  ],
  exports: [
    FormattableEditFieldComponent,
  ]
})
export class FormattableEditFieldModule { }

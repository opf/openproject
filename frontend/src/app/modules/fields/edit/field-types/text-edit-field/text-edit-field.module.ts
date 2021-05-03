import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from "@angular/forms";
import { TextEditFieldComponent } from "core-app/modules/fields/edit/field-types/text-edit-field/text-edit-field.component";
import { FocusModule } from "core-app/modules/focus/focus.module";

@NgModule({
  imports: [
    CommonModule,
    FormsModule,
    FocusModule,
  ],
  declarations: [
    TextEditFieldComponent,
  ],
  exports: [
    TextEditFieldComponent,
  ]
})
export class TextEditFieldModule { }

import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import {OpOptionListComponent} from "core-app/modules/common/option-list/option-list.component";



@NgModule({
  declarations: [
    OpOptionListComponent,
  ],
  imports: [
    CommonModule
  ],
  exports: [
    OpOptionListComponent,
  ]
})
export class OptionListModule { }

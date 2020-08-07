import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { QuerySpaceComponent } from './components/query-space/query-space.component';

@NgModule({
  declarations: [
    QuerySpaceComponent,
  ],
  imports: [
    CommonModule
  ],
  exports: [
    QuerySpaceComponent,
  ]
})
export class QuerySpaceModule { }

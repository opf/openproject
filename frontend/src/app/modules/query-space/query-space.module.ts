import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { QuerySpaceComponent } from './components/query-space/query-space.component';
import {UIRouterModule} from "@uirouter/angular";

@NgModule({
  declarations: [
    QuerySpaceComponent,
  ],
  imports: [
    CommonModule,
    UIRouterModule,
  ],
  exports: [
    QuerySpaceComponent,
  ]
})
export class QuerySpaceModule { }

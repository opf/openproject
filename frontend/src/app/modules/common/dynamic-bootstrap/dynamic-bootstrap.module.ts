import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { DynamicBootstrapDirective } from './directive/dynamic-bootstrap.directive';
import { DynamicBootstrapComponent } from './component/dynamic-bootstrap/dynamic-bootstrap.component';

@NgModule({
  declarations: [DynamicBootstrapDirective, DynamicBootstrapComponent],
  imports: [
    CommonModule
  ],
  exports: [DynamicBootstrapDirective],
})
export class DynamicBootstrapModule { }

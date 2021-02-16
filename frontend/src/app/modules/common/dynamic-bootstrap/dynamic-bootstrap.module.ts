/**
 * @module
 * DynamicBootstrapComponent allows to dynamically render an HTML string into any HTML node
 * and bootstrap its Angular components and directives.
 *
 * @usageNotes
 * ```
 *  <op-dynamic-bootstrap HTML="<macro data-id="1" data-detailed="false" title="Macro nº1"></macro>">
 *  </op-dynamic-bootstrap>
 * ```
 */

import { NgModule } from '@angular/core';
import { DynamicBootstrapComponent } from './component/dynamic-bootstrap/dynamic-bootstrap.component';

@NgModule({
  declarations: [DynamicBootstrapComponent],
  exports: [DynamicBootstrapComponent],
})
export class DynamicBootstrapModule { }

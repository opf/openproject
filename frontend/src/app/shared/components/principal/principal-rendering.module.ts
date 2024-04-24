import { Injector, NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { OpPrincipalComponent } from './principal.component';
import { PrincipalRendererService } from './principal-renderer.service';

@NgModule({
  imports: [
    CommonModule,
  ],
  exports: [
    OpPrincipalComponent,
  ],
  providers: [
    PrincipalRendererService,
  ],
  declarations: [
    OpPrincipalComponent,
  ],
})
export class OpenprojectPrincipalRenderingModule {
  constructor(readonly injector:Injector) {
  }
}

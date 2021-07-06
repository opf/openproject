import { NgModule } from '@angular/core';
import { OpPrincipalComponent } from './principal.component';
import { PrincipalRendererService } from './principal-renderer.service';

@NgModule({
  imports: [],
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
export class OpenprojectPrincipalRenderingModule { }

import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { OpPrincipalComponent } from './principal.component';
import { OpPrincipalListComponent } from './principal-list.component';
import { PrincipalRendererService } from './principal-renderer.service';

@NgModule({
  imports: [
    CommonModule,
  ],
  exports: [
    OpPrincipalComponent,
    OpPrincipalListComponent,
  ],
  providers: [
    PrincipalRendererService,
  ],
  declarations: [
    OpPrincipalComponent,
    OpPrincipalListComponent,
  ],
})
export class OpenprojectPrincipalRenderingModule { }

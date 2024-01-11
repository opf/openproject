import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { OpIconComponent } from './icon.component';
import {
  OpEnterpriseAddonsIconComponent,
  ShareAndroidIconComponent,
  XIconComponent,
} from '@openproject/octicons-angular';

@NgModule({
  imports: [
    CommonModule,

    ShareAndroidIconComponent,
    XIconComponent,
    OpEnterpriseAddonsIconComponent,
  ],
  declarations: [
    OpIconComponent,
  ],
  providers: [
  ],
  exports: [
    OpIconComponent,

    ShareAndroidIconComponent,
    XIconComponent,
    OpEnterpriseAddonsIconComponent,
  ],
})
export class IconModule {}

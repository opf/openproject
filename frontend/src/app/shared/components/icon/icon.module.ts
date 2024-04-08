import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { OpIconComponent } from './icon.component';
import {
  OpEnterpriseAddonsIconComponent,
  ShareAndroidIconComponent,
  StarFillIconComponent,
  StarIconComponent,
  XIconComponent,
} from '@openproject/octicons-angular';

@NgModule({
  imports: [
    CommonModule,

    ShareAndroidIconComponent,
    XIconComponent,
    OpEnterpriseAddonsIconComponent,
    StarFillIconComponent,
    StarIconComponent,
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
    StarFillIconComponent,
    StarIconComponent,
  ],
})
export class IconModule {}

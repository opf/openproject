import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { OpIconComponent } from './icon.component';
import {
  ShareAndroidIconComponent,
  XIconComponent,
} from '@openproject/octicons-angular';

@NgModule({
  imports: [
    CommonModule,

    ShareAndroidIconComponent,
    XIconComponent,
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
  ],
})
export class IconModule {}

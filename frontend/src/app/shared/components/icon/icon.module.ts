import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { OpIconComponent } from './icon.component';
import { ShareAndroidIconComponent } from '@openproject/octicons-angular';

@NgModule({
  imports: [
    CommonModule,

    ShareAndroidIconComponent,
  ],
  declarations: [
    OpIconComponent,
  ],
  providers: [
  ],
  exports: [
    OpIconComponent,

    ShareAndroidIconComponent,
  ],
})
export class IconModule {}

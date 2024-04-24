import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { OpIconComponent } from './icon.component';
import {
  HomeIconComponent,
  InfoIconComponent,
  OpCursorRectangleSelectIconComponent,
  OpCursorSelectIconComponent,
  OpEnterpriseAddonsIconComponent,
  OpEraseIconComponent,
  OpGridMenuIconComponent,
  OpScissorsIconComponent,
  OpViewModalIconComponent,
  PackageIconComponent,
  PersonIconComponent,
  ScreenFullIconComponent,
  ShareAndroidIconComponent,
  XIconComponent,
} from '@openproject/octicons-angular';

@NgModule({
  imports: [
    CommonModule,

    HomeIconComponent,
    InfoIconComponent,
    OpCursorRectangleSelectIconComponent,
    OpCursorSelectIconComponent,
    OpEnterpriseAddonsIconComponent,
    OpEraseIconComponent,
    OpGridMenuIconComponent,
    OpScissorsIconComponent,
    OpViewModalIconComponent,
    PackageIconComponent,
    PersonIconComponent,
    ScreenFullIconComponent,
    ShareAndroidIconComponent,
    XIconComponent,
  ],
  declarations: [
    OpIconComponent,
  ],
  providers: [],
  exports: [
    OpIconComponent,

    HomeIconComponent,
    InfoIconComponent,
    OpCursorRectangleSelectIconComponent,
    OpCursorSelectIconComponent,
    OpEnterpriseAddonsIconComponent,
    OpEraseIconComponent,
    OpGridMenuIconComponent,
    OpScissorsIconComponent,
    OpViewModalIconComponent,
    PackageIconComponent,
    PersonIconComponent,
    ScreenFullIconComponent,
    ShareAndroidIconComponent,
    XIconComponent,
  ],
})
export class IconModule {}

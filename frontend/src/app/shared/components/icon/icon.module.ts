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
  StarFillIconComponent,
  StarIconComponent,
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
    StarFillIconComponent,
    StarIconComponent,
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
    OpEnterpriseAddonsIconComponent,
    StarFillIconComponent,
    StarIconComponent,
  ],
})
export class IconModule {}

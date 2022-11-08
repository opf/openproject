import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FocusModule } from 'core-app/shared/directives/focus/focus.module';
import { IconModule } from 'core-app/shared/components/icon/icon.module';
import { OpModalService } from './modal.service';
import { OpModalWrapperAugmentService } from './modal-wrapper-augment.service';
import { OpModalBannerComponent } from 'core-app/shared/components/modal/modal-banner/modal-banner.component';

@NgModule({
  imports: [
    CommonModule,
    FocusModule,
    IconModule,
  ],
  exports: [
    OpModalBannerComponent,
  ],
  providers: [
    OpModalService,
    OpModalWrapperAugmentService,
  ],
  declarations: [
    OpModalBannerComponent,
  ],
})
export class OpenprojectModalModule { }

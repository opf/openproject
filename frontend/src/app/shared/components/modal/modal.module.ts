import { NgModule } from '@angular/core';
import { PortalModule } from '@angular/cdk/portal';
import { A11yModule } from '@angular/cdk/a11y';
import { FocusModule } from 'core-app/shared/directives/focus/focus.module';
import { IconModule } from 'core-app/shared/components/icon/icon.module';
import { OpModalWrapperAugmentService } from './modal-wrapper-augment.service';
import { OpModalBannerComponent } from 'core-app/shared/components/modal/modal-banner/modal-banner.component';
import { OpModalOverlayComponent } from 'core-app/shared/components/modal/modal-overlay.component';
import { CommonModule } from '@angular/common';
import { OpCustomModalOverlayComponent } from 'core-app/shared/components/modal/custom-modal-overlay.component';

@NgModule({
  imports: [
    CommonModule,
    FocusModule,
    IconModule,
    PortalModule,
    A11yModule,
  ],
  exports: [
    OpModalOverlayComponent,
    OpCustomModalOverlayComponent,
    OpModalBannerComponent,
  ],
  providers: [
    OpModalWrapperAugmentService,
  ],
  declarations: [
    OpModalBannerComponent,
    OpModalOverlayComponent,
    OpCustomModalOverlayComponent,
  ],
})
export class OpenprojectModalModule { }

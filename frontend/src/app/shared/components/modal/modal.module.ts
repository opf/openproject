//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) the OpenProject GmbH
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2013 Jean-Philippe Lang
// Copyright (C) 2010-2013 the ChiliProject Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

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
import { ModalWithTurboContentDirective } from 'core-app/shared/components/fields/edit/modal-with-turbo-content/modal-with-turbo-content.directive';

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
    ModalWithTurboContentDirective,
  ],
  providers: [
    OpModalWrapperAugmentService,
  ],
  declarations: [
    OpModalBannerComponent,
    OpModalOverlayComponent,
    OpCustomModalOverlayComponent,
    ModalWithTurboContentDirective,
  ],
})
export class OpenprojectModalModule { }

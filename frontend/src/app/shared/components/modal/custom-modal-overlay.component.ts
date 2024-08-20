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
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import {
  ChangeDetectionStrategy,
  Component,
} from '@angular/core';

import { ModalData } from 'core-app/shared/components/modal/modal.service';
import { OpModalOverlayComponent } from 'core-app/shared/components/modal/modal-overlay.component';
import { PortalOutletTarget } from 'core-app/shared/components/modal/portal-outlet-target.enum';

export const opCustomModalOverlaySelector = 'op-custom-modal-overlay';

@Component({
  selector: opCustomModalOverlaySelector,
  templateUrl: './modal-overlay.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class OpCustomModalOverlayComponent extends OpModalOverlayComponent {
  protected isDefaultTarget(modalData:ModalData | null):boolean {
    if (modalData === null) return true;

    return modalData.target === PortalOutletTarget.Custom;
  }
}

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
  ConfirmDialogModalComponent,
  ConfirmDialogOptions,
} from 'core-app/shared/components/modals/confirm-dialog/confirm-dialog.modal';
import { OpModalService } from 'core-app/shared/components/modal/modal.service';
import {
  Injectable,
  Injector,
} from '@angular/core';

@Injectable()
export class ConfirmDialogService {
  constructor(
    readonly opModalService:OpModalService,
    readonly injector:Injector,
  ) {
    document.addEventListener('submit', (evt:Event) => {
      const target = evt.target as HTMLFormElement;
      const options = target.dataset.augmentedConfirmDialog;
      if (options) {
        this.augmentFormSubmit(target, JSON.parse(options));

        evt.preventDefault();
        return false;
      }

      return true;
    });
  }

  /**
   * Confirm an action with an ng dialog with the given options
   */
  public confirm(options:ConfirmDialogOptions):Promise<void> {
    return new Promise<void>((resolve, reject) => {
      this.opModalService.show(
        ConfirmDialogModalComponent,
        this.injector,
        { options },
      ).subscribe((modal) => modal.closingEvent.subscribe(() => {
        if (modal.confirmed) {
          resolve();
        } else {
          reject();
        }
      }));
    });
  }

  /**
   * Augment a Rails form submit with a confirmation dialog
   *
   * @param target
   * @param options
   * @private
   */
  private augmentFormSubmit(target:HTMLFormElement, options:ConfirmDialogOptions) {
    void this
      .confirm(options)
      .then(() => {
        target.removeAttribute('data-augmented-confirm-dialog');
        target.submit();
      })
      .catch(() => undefined /* Dialog cancelled, nothing to do */);
  }
}

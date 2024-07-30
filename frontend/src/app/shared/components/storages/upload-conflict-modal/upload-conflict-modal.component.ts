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
  ChangeDetectorRef,
  Component,
  ElementRef,
  Inject,
} from '@angular/core';

import { I18nService } from 'core-app/core/i18n/i18n.service';
import { OpModalLocalsMap } from 'core-app/shared/components/modal/modal.types';
import { OpModalComponent } from 'core-app/shared/components/modal/modal.component';
import { OpModalLocalsToken } from 'core-app/shared/components/modal/modal.service';

@Component({
  templateUrl: 'upload-conflict-modal.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class UploadConflictModalComponent extends OpModalComponent {
  public overwrite:boolean|null = null;

  public text = {
    header: this.i18n.t('js.storages.files.already_existing_header'),
    body: () => this.i18n.t('js.storages.files.already_existing_body', { fileName: this.locals.fileName as string }),
    buttons: {
      keepBoth: this.i18n.t('js.storages.files.upload_keep_both'),
      replace: this.i18n.t('js.storages.files.upload_replace'),
      cancel: this.i18n.t('js.button_cancel'),
    },
  };

  public constructor(
    @Inject(OpModalLocalsToken) public locals:OpModalLocalsMap,
    readonly cdRef:ChangeDetectorRef,
    readonly elementRef:ElementRef,
    private readonly i18n:I18nService,
  ) {
    super(locals, cdRef, elementRef);
  }

  public close(overwrite:boolean):void {
    this.overwrite = overwrite;
    this.service.close();
  }
}

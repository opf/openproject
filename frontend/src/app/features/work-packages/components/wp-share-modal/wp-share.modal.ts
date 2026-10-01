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

import { ChangeDetectionStrategy, Component, ElementRef, OnInit, ViewChild, inject } from '@angular/core';
import { OpModalComponent } from 'core-app/shared/components/modal/modal.component';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { ActionsService } from 'core-app/core/state/actions/actions.service';
import { shareModalUpdated } from 'core-app/features/work-packages/components/wp-share-modal/sharing.actions';
import { type FrameElement } from '@hotwired/turbo';

@Component({
  templateUrl: './wp-share.modal.html',
  styleUrls: ['./wp-share.modal.sass'],
  changeDetection: ChangeDetectionStrategy.OnPush,
  standalone: false,
})
export class WorkPackageShareModalComponent extends OpModalComponent implements OnInit {
  readonly I18n = inject(I18nService);
  readonly pathHelper = inject(PathHelperService);
  readonly actions$ = inject(ActionsService);

  @ViewChild('frameElement') frameElement:ElementRef<FrameElement>|undefined;

  // Hide close button so it's not duplicated in primer (WP#51699)
  showCloseButton = false;

  private workPackage:WorkPackageResource;
  public frameSrc:string;

  text = {
    title: this.I18n.t('js.work_packages.sharing.title'),
    button_close: this.I18n.t('js.button_close'),
  };

  constructor() {
    super();

    this.workPackage = this.locals.workPackage as WorkPackageResource;
    this.frameSrc = this.pathHelper.workPackageSharePath(this.workPackage.id!);
  }

  ngOnInit() {
    super.ngOnInit();
  }

  onClose():boolean {
    this.actions$.dispatch(shareModalUpdated({ workPackageId: this.workPackage.id! }));

    return super.onClose();
  }
}

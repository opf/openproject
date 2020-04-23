// -- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2020 the OpenProject GmbH
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
// See docs/COPYRIGHT.rdoc for more details.
// ++

import {WorkPackageResource} from 'core-app/modules/hal/resources/work-package-resource';

import {HalResourceEditingService} from "core-app/modules/fields/edit/services/hal-resource-editing.service";
import {ChangeDetectorRef, Component, Input, OnInit} from '@angular/core';
import {I18nService} from 'core-app/modules/common/i18n/i18n.service';
import {Highlighting} from "core-components/wp-fast-table/builders/highlighting/highlighting.functions";
import {HalResource} from "core-app/modules/hal/resources/hal-resource";
import {WorkPackageCacheService} from "core-components/work-packages/work-package-cache.service";
import {UntilDestroyedMixin} from "core-app/helpers/angular/until-destroyed.mixin";

@Component({
  selector: 'wp-status-button',
  styleUrls: ['./wp-status-button.component.sass'],
  templateUrl: './wp-status-button.html'
})
export class WorkPackageStatusButtonComponent extends UntilDestroyedMixin implements OnInit {
  @Input('workPackage') public workPackage:WorkPackageResource;
  @Input('containerClass') public containerClass:string;

  public text = {
    explanation: this.I18n.t('js.label_edit_status'),
    workPackageReadOnly: this.I18n.t('js.work_packages.message_work_package_read_only'),
    workPackageStatusBlocked: this.I18n.t('js.work_packages.message_work_package_status_blocked')
  };

  constructor(readonly I18n:I18nService,
              readonly cdRef:ChangeDetectorRef,
              readonly wpCacheService:WorkPackageCacheService,
              readonly halEditing:HalResourceEditingService) {
    super();
  }

  ngOnInit() {
    this.halEditing
      .temporaryEditResource(this.workPackage)
      .values$()
      .pipe(
        this.untilDestroyed()
      )
      .subscribe((wp) => {
        this.workPackage = wp;
        this.cdRef.detectChanges();

        if (this.workPackage.status) {
          this.workPackage.status.$load();
        }
      });
  }

  public get buttonTitle() {
    if (this.workPackage.isReadonly) {
      return this.text.workPackageReadOnly;
    } else if (this.workPackage.isEditable && this.isDisabled) {
      return this.text.workPackageStatusBlocked;
    } else {
      return '';
    }
  }

  public get statusHighlightClass() {
    let status = this.status;
    if (!status) {
      return;
    }
    return Highlighting.backgroundClass('status', status.id!);
  }

  public get status():HalResource|undefined {
    if (!this.halEditing) {
      return;
    }

    return this.changeset.projectedResource.status;
  }

  public get allowed() {
    return this.workPackage.isAttributeEditable('status');
  }

  public get isDisabled() {
    let writable = this.changeset.isWritable('status');

    return !this.allowed || !writable || this.changeset.inFlight;
  }

  private get changeset() {
    return this.halEditing.changeFor(this.workPackage);
  }
}

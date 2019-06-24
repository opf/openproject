// -- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
// See doc/COPYRIGHT.rdoc for more details.
// ++

import {WorkPackageResource} from 'core-app/modules/hal/resources/work-package-resource';
import {WorkPackageEditingService} from 'core-components/wp-edit-form/work-package-editing-service';
import {ChangeDetectorRef, Component, Inject, Input, OnDestroy, OnInit} from '@angular/core';
import {I18nService} from 'core-app/modules/common/i18n/i18n.service';
import {IWorkPackageEditingServiceToken} from "../../wp-edit-form/work-package-editing.service.interface";
import {Highlighting} from "core-components/wp-fast-table/builders/highlighting/highlighting.functions";
import {HalResource} from "core-app/modules/hal/resources/hal-resource";
import {WorkPackageCacheService} from "core-components/work-packages/work-package-cache.service";
import {untilComponentDestroyed} from "ng2-rx-componentdestroyed";
import {SchemaCacheService} from "core-components/schemas/schema-cache.service";

@Component({
  selector: 'wp-status-button',
  styleUrls: ['./wp-status-button.component.sass'],
  templateUrl: './wp-status-button.html'
})
export class WorkPackageStatusButtonComponent implements OnInit, OnDestroy {
  @Input('workPackage') public workPackage:WorkPackageResource;
  @Input('containerClass') public containerClass:string;

  public text = {
    explanation: this.I18n.t('js.label_edit_status'),
    workPackageReadOnly: this.I18n.t('js.work_packages.message_work_package_read_only')
  };

  constructor(readonly I18n:I18nService,
              readonly cdRef:ChangeDetectorRef,
              readonly wpCacheService:WorkPackageCacheService,
              readonly schemaCacheService:SchemaCacheService,
              readonly changeDetectorRef:ChangeDetectorRef,
              @Inject(IWorkPackageEditingServiceToken) protected wpEditing:WorkPackageEditingService) {
  }

  ngOnInit() {
    this.wpCacheService
      .observe(this.workPackage.id!)
      .pipe(
        untilComponentDestroyed(this)
      )
      .subscribe((wp) => {
        this.workPackage = wp;
        this.cdRef.detectChanges();
        this.workPackage.status.$load();
      });

    this.schemaCacheService
      .state(this.workPackage)
      .changes$()
      .pipe(
        untilComponentDestroyed(this)
      )
      .subscribe((wp) => {
        // we have to explicitly force the component to update
        this.changeDetectorRef.detectChanges();
      });
  }

  ngOnDestroy():void {
    // Nothing to do
  }

  public get buttonTitle() {
    if (this.workPackage.isReadonly) {
      return this.text.workPackageReadOnly;
    } else {
      return '';
    }
  }

  public get statusHighlightClass() {
    let status = this.status;
    if (!status) { return; }
    return Highlighting.backgroundClass('status', status.id!);
  }

  public get status():HalResource|undefined {
    if (!this.wpEditing) { return; }

    return this.changeset.value('status');
  }

  public get allowed() {
    return this.workPackage.isAttributeEditable('status');
  }

  public get isDisabled() {
    let writable = this.changeset.isWritable('status');

    return !this.allowed || !writable || this.changeset.inFlight;
  }

  private get changeset() {
    return this.wpEditing.changesetFor(this.workPackage);
  }
}

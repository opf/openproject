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
// along with this program. If not, see <https://www.gnu.org/licenses/>.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { HalResourceEditingService } from 'core-app/shared/components/fields/edit/services/hal-resource-editing.service';
import { ChangeDetectorRef, Component, DestroyRef, Input, OnChanges, SimpleChanges, inject } from '@angular/core';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';
import { EMPTY, Subscription, catchError, from, switchMap, tap } from 'rxjs';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { Highlighting } from 'core-app/features/work-packages/components/wp-fast-table/builders/highlighting/highlighting.functions';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { SchemaCacheService } from 'core-app/core/schemas/schema-cache.service';

@Component({
  // eslint-disable-next-line @angular-eslint/component-selector
  selector: 'wp-status-button',
  styleUrls: ['./wp-status-button.component.sass'],
  templateUrl: './wp-status-button.html',
  standalone: false,
})
export class WorkPackageStatusButtonComponent implements OnChanges {
  readonly I18n = inject(I18nService);
  readonly cdRef = inject(ChangeDetectorRef);
  readonly schemaCache = inject(SchemaCacheService);
  readonly halEditing = inject(HalResourceEditingService);

  private readonly destroyRef = inject(DestroyRef);
  private workPackageSubscription?:Subscription;
  protected currentWorkPackage:WorkPackageResource;

  @Input() public workPackage:WorkPackageResource;

  @Input() public small = false;

  public text = {
    status: this.I18n.t('js.work_packages.properties.status'),
    workPackageReadOnly: this.I18n.t('js.work_packages.message_work_package_read_only'),
    workPackageStatusBlocked: this.I18n.t('js.work_packages.message_work_package_status_blocked'),
  };

  ngOnChanges(changes:SimpleChanges<WorkPackageStatusButtonComponent>):void {
    if (!changes.workPackage) {
      return;
    }

    this.workPackageSubscription?.unsubscribe();
    this.currentWorkPackage = this.workPackage;
    this.workPackageSubscription = this.halEditing
      .observeTemporaryEditResource(this.workPackage)
      .pipe(
        tap((workPackage) => {
          this.currentWorkPackage = workPackage;
          this.cdRef.markForCheck();
        }),
        switchMap(({ status }) => status ? from(status.$load()).pipe(catchError(() => EMPTY)) : EMPTY),
        takeUntilDestroyed(this.destroyRef),
      )
      .subscribe(() => this.cdRef.markForCheck());
  }

  public get disabledReason():string|null {
    if (this.schema.isReadonly) {
      return this.text.workPackageReadOnly;
    } if (this.schema.isEditable && !this.allowed) {
      return this.text.workPackageStatusBlocked;
    }
    return null;
  }

  public get statusHighlightClass() {
    const { status } = this;
    if (!status) {
      return;
    }
    return Highlighting.backgroundClass('status', status.id!);
  }

  public get status():HalResource {
    return this.currentWorkPackage.status;
  }

  public get isReadonly() {
    return this.schema.isReadonly;
  }

  public get allowed() {
    return this.schema.isAttributeEditable('status');
  }

  private get schema() {
    const change = this.halEditing.typedState(this.currentWorkPackage).value;
    return change?.schema ?? this.schemaCache.of(this.currentWorkPackage);
  }
}

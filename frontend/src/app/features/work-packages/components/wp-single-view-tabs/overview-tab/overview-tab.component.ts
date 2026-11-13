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

import { ChangeDetectorRef, Component, DestroyRef, Input, OnChanges, inject } from '@angular/core';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';
import { Subscription } from 'rxjs';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';

@Component({
  templateUrl: './overview-tab.html',
  // eslint-disable-next-line @angular-eslint/component-selector
  selector: 'wp-overview-tab',
  standalone: false,
})
export class WorkPackageOverviewTabComponent implements OnChanges {
  readonly I18n = inject(I18nService);
  readonly apiV3Service = inject(ApiV3Service);
  readonly cdRef = inject(ChangeDetectorRef);

  private readonly destroyRef = inject(DestroyRef);
  private workPackageSubscription?:Subscription;

  @Input() public workPackage:WorkPackageResource;

  public workPackageId:string;

  public tabName = this.I18n.t('js.label_latest_activity');

  ngOnChanges():void {
    if (this.workPackage.id === this.workPackageId) {
      return;
    }

    this.workPackageSubscription?.unsubscribe();
    this.workPackageId = this.workPackage.id!;

    this.workPackageSubscription = this.apiV3Service
      .work_packages
      .id(this.workPackageId)
      .requireAndStream()
      .pipe(takeUntilDestroyed(this.destroyRef))
      .subscribe((wp) => {
        this.workPackage = wp;
        this.cdRef.markForCheck();
      });
  }
}

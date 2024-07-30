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

import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { ChangeDetectionStrategy, ChangeDetectorRef, Component, Input, OnInit } from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { UntilDestroyedMixin } from 'core-app/shared/helpers/angular/until-destroyed.mixin';
import { OpModalService } from 'core-app/shared/components/modal/modal.service';
import {
  WorkPackageShareModalComponent,
} from 'core-app/features/work-packages/components/wp-share-modal/wp-share.modal';
import { BannersService } from 'core-app/core/enterprise/banners.service';
import { ApiV3FilterBuilder } from 'core-app/shared/helpers/api-v3/api-v3-filter-builder';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { filter, map, startWith, switchMap } from 'rxjs/operators';
import { Observable } from 'rxjs';
import { ActionsService } from 'core-app/core/state/actions/actions.service';
import { shareModalUpdated } from 'core-app/features/work-packages/components/wp-share-modal/sharing.actions';
import { CollectionResource } from 'core-app/features/hal/resources/collection-resource';

@Component({
  // eslint-disable-next-line @angular-eslint/component-selector
  selector: 'wp-share-button',
  templateUrl: './wp-share-button.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class WorkPackageShareButtonComponent extends UntilDestroyedMixin implements OnInit {
  @Input() public workPackage:WorkPackageResource;

  showEnterpriseIcon = this.bannersService.eeShowBanners;

  shareCount$:Observable<number>;

  public text = {
    share: this.I18n.t('js.sharing.share'),
  };

  constructor(
    readonly I18n:I18nService,
    readonly opModalService:OpModalService,
    readonly cdRef:ChangeDetectorRef,
    readonly bannersService:BannersService,
    readonly apiV3Service:ApiV3Service,
    readonly actions$:ActionsService,
  ) {
    super();
  }

  ngOnInit() {
    this.shareCount$ = this
      .actions$
      .ofType(shareModalUpdated)
      .pipe(
        map((action) => action.workPackageId),
        filter((id) => id === this.workPackage.id?.toString()),
        startWith(null),
        switchMap(() => this.countShares()),
      );
  }

  openModal():void {
    this.opModalService.show(WorkPackageShareModalComponent, 'global', { workPackage: this.workPackage }, false, true);
  }

  private countShares():Observable<number> {
    const filters = new ApiV3FilterBuilder()
      .add('entityType', '=', ['WorkPackage'])
      .add('entityId', '=', [this.workPackage.id as string]);

    return this
      .apiV3Service
      .shares
      .filtered(filters, { pageSize: '0 ' })
      .get()
      .pipe(
        map((collection:CollectionResource) => collection.total),
      );
  }
}

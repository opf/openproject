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

import {
  ChangeDetectionStrategy, ChangeDetectorRef, Component, Input, OnInit,
} from '@angular/core';
import { UntilDestroyedMixin } from 'core-app/shared/helpers/angular/until-destroyed.mixin';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { WorkPackageWatchersService } from 'core-app/features/work-packages/components/wp-single-view-tabs/watchers-tab/wp-watchers.service';

@Component({
  templateUrl: './wp-relations-count.html',
  selector: 'wp-watchers-count',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class WorkPackageWatchersCountComponent extends UntilDestroyedMixin implements OnInit {
  @Input() wpId:string;

  public count = 0;

  constructor(protected apiV3Service:ApiV3Service,
    protected wpWatcherService:WorkPackageWatchersService,
    protected cdRef:ChangeDetectorRef) {
    super();
  }

  ngOnInit():void {
    this
      .apiV3Service
      .work_packages
      .id(this.wpId)
      .requireAndStream()
      .pipe(
        this.untilDestroyed(),
      ).subscribe((workPackage) => {
        this.wpWatcherService
          .require(workPackage)
          .then((watchers:HalResource[]) => {
            this.count = watchers.length;
            this.cdRef.detectChanges();
          });
      });
  }
}

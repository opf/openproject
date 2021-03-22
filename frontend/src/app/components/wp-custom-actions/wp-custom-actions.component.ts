//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2021 the OpenProject GmbH
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
//++

import { ChangeDetectionStrategy, ChangeDetectorRef, Component, Input, OnInit } from '@angular/core';
import { WorkPackageResource } from 'core-app/modules/hal/resources/work-package-resource';
import { APIV3Service } from "core-app/modules/apiv3/api-v3.service";
import { CustomActionResource } from "core-app/modules/hal/resources/custom-action-resource";
import { UntilDestroyedMixin } from "core-app/helpers/angular/until-destroyed.mixin";

@Component({
  selector: 'wp-custom-actions',
  templateUrl: './wp-custom-actions.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class WpCustomActionsComponent extends UntilDestroyedMixin implements OnInit {

  @Input() workPackage:WorkPackageResource;

  actions:CustomActionResource[] = [];

  constructor(readonly apiV3Service:APIV3Service,
              readonly cdRef:ChangeDetectorRef) {
    super();
  }

  ngOnInit() {
    this
      .apiV3Service
      .work_packages
      .id(this.workPackage.id!)
      .requireAndStream()
      .pipe(
        this.untilDestroyed()
      )
      .subscribe((wp) => {
        this.actions = wp.customActions ? [...wp.customActions] : [];
        this.cdRef.detectChanges();
      });
  }

}

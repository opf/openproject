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

import {Component, Input, OnInit} from '@angular/core';
import {UIRouterGlobals} from '@uirouter/core';
import {WorkPackageResource} from 'core-app/modules/hal/resources/work-package-resource';
import {WorkPackageCacheService} from '../work-package-cache.service';
import {randomString} from "core-app/helpers/random-string";
import {UntilDestroyedMixin} from "core-app/helpers/angular/until-destroyed.mixin";

@Component({
  selector: 'wp-subject',
  templateUrl: './wp-subject.html'
})
export class WorkPackageSubjectComponent extends UntilDestroyedMixin implements OnInit {
  @Input('workPackage') workPackage:WorkPackageResource;

  public readonly uniqueElementIdentifier = `work-packages--subject-type-row-${randomString(16)}`;

  constructor(protected uiRouterGlobals:UIRouterGlobals,
              protected wpCacheService:WorkPackageCacheService) {
    super();
  }

  ngOnInit() {
    if (!this.workPackage) {
      this.wpCacheService.loadWorkPackage(this.uiRouterGlobals.params['workPackageId'])
        .values$()
        .pipe(
          this.untilDestroyed()
        )
        .subscribe((wp:WorkPackageResource) => {
          this.workPackage = wp;
        });
    }
  }
}

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

import {Component, Input, OnDestroy, OnInit} from '@angular/core';
import {UIRouterGlobals} from '@uirouter/core';
import {componentDestroyed} from 'ng2-rx-componentdestroyed';
import {takeUntil} from 'rxjs/operators';
import {WorkPackageResource} from 'core-app/modules/hal/resources/work-package-resource';
import {WorkPackageCacheService} from '../work-package-cache.service';
import {randomString} from "core-app/helpers/random-string";

@Component({
  selector: 'wp-subject',
  templateUrl: './wp-subject.html'
})
export class WorkPackageSubjectComponent implements OnInit, OnDestroy {
  @Input('workPackage') workPackage:WorkPackageResource;

  public readonly uniqueElementIdentifier = `work-packages--subject-type-row-${randomString(16)}`;

  constructor(protected uiRouterGlobals:UIRouterGlobals,
              protected wpCacheService:WorkPackageCacheService) {
  }

  ngOnDestroy() {
    // Nothing to do
  }

  ngOnInit() {
    if (!this.workPackage) {
      this.wpCacheService.loadWorkPackage(this.uiRouterGlobals.params['workPackageId'])
        .values$()
        .pipe(
          takeUntil(componentDestroyed(this))
        )
        .subscribe((wp:WorkPackageResource) => {
          this.workPackage = wp;
        });
    }
  }
}

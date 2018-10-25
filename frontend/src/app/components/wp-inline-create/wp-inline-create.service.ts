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

import {Injectable, OnDestroy} from '@angular/core';
import {WorkPackageResource} from 'core-app/modules/hal/resources/work-package-resource';
import {Observable, Subject} from "rxjs";
import {ComponentType} from "@angular/cdk/portal";

@Injectable()
export class WorkPackageInlineCreateService implements OnDestroy {

  /** Allow callbacks to happen on newly created inline work packages */
  protected _newInlineWorkPackage = new Subject<WorkPackageResource>();

  /**
   * Ensure hierarchical injected versions of this service correctly unregister
   */
  ngOnDestroy() {
    this._newInlineWorkPackage.complete();
  }

  /**
   * Returns an observable that fires whenever a new INLINE work packages was created.
   */
  public newInlineWorkPackageCreated$():Observable<WorkPackageResource> {
    return this._newInlineWorkPackage.asObservable();
  }

  public get referenceComponentClass():ComponentType<any>|null {
    return null;
  }

  /**
   * Notify of a new inline work package that was created
   * @param wp Work package that got created
   */
  public newInlineWorkPackage(wp:WorkPackageResource) {
    this._newInlineWorkPackage.next(wp);
  }
}

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

import {
  Component,
  ElementRef, HostListener,
  Inject, Injectable,
  Injector,
  Input,
  OnChanges,
  OnDestroy,
  OnInit
} from '@angular/core';
import {AuthorisationService} from 'core-app/modules/common/model-auth/model-auth.service';
import {WorkPackageTableFocusService} from 'core-components/wp-fast-table/state/wp-table-focus.service';
import {filter, takeUntil} from 'rxjs/operators';
import {WorkPackageResource} from 'core-app/modules/hal/resources/work-package-resource';
import {WorkPackageCacheService} from '../work-packages/work-package-cache.service';
import {TableRowEditContext} from '../wp-edit-form/table-row-edit-context';
import {WorkPackageChangeset} from '../wp-edit-form/work-package-changeset';
import {WorkPackageEditForm} from '../wp-edit-form/work-package-edit-form';
import {WorkPackageEditingService} from '../wp-edit-form/work-package-editing-service';
import {WorkPackageFilterValues} from '../wp-edit-form/work-package-filter-values';
import {TimelineRowBuilder} from '../wp-fast-table/builders/timeline/timeline-row-builder';
import {onClickOrEnter} from '../wp-fast-table/handlers/click-or-enter-handler';
import {WorkPackageTableColumnsService} from '../wp-fast-table/state/wp-table-columns.service';
import {WorkPackageTableFiltersService} from '../wp-fast-table/state/wp-table-filters.service';
import {WorkPackageTable} from '../wp-fast-table/wp-fast-table';
import {WorkPackageCreateService} from '../wp-new/wp-create.service';
import {
  inlineCreateCancelClassName,
  InlineCreateRowBuilder,
  inlineCreateRowClassName
} from './inline-create-row-builder';
import {TableState} from 'core-components/wp-table/table-state/table-state';
import {componentDestroyed} from 'ng2-rx-componentdestroyed';
import {I18nService} from 'core-app/modules/common/i18n/i18n.service';
import {FocusHelperService} from 'core-app/modules/common/focus/focus-helper';
import {IWorkPackageEditingServiceToken} from "../wp-edit-form/work-package-editing.service.interface";
import {IWorkPackageCreateServiceToken} from "core-components/wp-new/wp-create.service.interface";
import {CurrentUserService} from "core-components/user/current-user.service";
import {Observable, Subject} from "rxjs";

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

  /**
   * Notify of a new inline work package that was created
   * @param wp Work package that got created
   */
  public newInlineWorkPackage(wp:WorkPackageResource) {
    this._newInlineWorkPackage.next(wp);
  }
}

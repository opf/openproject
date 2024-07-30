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

import {
  Injectable,
  Injector,
  OnDestroy,
} from '@angular/core';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import {
  Observable,
  of,
  Subject,
} from 'rxjs';
import { ComponentType } from '@angular/cdk/portal';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { InjectField } from 'core-app/shared/helpers/angular/inject-field.decorator';
import { CurrentUserService } from 'core-app/core/current-user/current-user.service';
import { CurrentProjectService } from 'core-app/core/current-project/current-project.service';

@Injectable()
export class WorkPackageInlineCreateService implements OnDestroy {
  @InjectField() I18n!:I18nService;

  @InjectField() protected readonly currentUser:CurrentUserService;

  @InjectField() protected readonly currentProject:CurrentProjectService;

  constructor(readonly injector:Injector) {
  }

  /**
   * A separate reference pane for the inline create component
   */
  public readonly referenceComponentClass:ComponentType<any>|null = null;

  /**
   * A related work package for the inline create context
   */
  public referenceTarget:WorkPackageResource|null = null;

  /**
   * Reference button text
   */
  public readonly buttonTexts = {
    reference: '',
    create: this.I18n.t('js.label_create_work_package'),
  };

  public get canAdd():Observable<boolean> {
    return this.canCreateWorkPackages();
  }

  public get canReference():Observable<boolean> {
    return of(false);
  }

  /**
   * Observable capability check for work_packages/create and /edit.
   * Edit is included as inline create saves quickly, preventing further edits for users
   * that don't also have edit permisison.
   *
   * @protected
   */
  protected canCreateWorkPackages(projectId:string|null = this.currentProject.id):Observable<boolean> {
    return this
      .currentUser
      .hasCapabilities$(
        ['work_packages/create', 'work_packages/update'],
        projectId || null,
      );
  }

  /** Allow callbacks to happen on newly created inline work packages */
  public newInlineWorkPackageCreated = new Subject<string>();

  /** Allow callbacks to happen on newly created inline work packages */
  public newInlineWorkPackageReferenced = new Subject<string>();

  /**
   * Ensure hierarchical injected versions of this service correctly unregister
   */
  ngOnDestroy():void {
    this.newInlineWorkPackageCreated.complete();
    this.newInlineWorkPackageReferenced.complete();
  }
}

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

import { Injectable, Type } from '@angular/core';
import type { HalResource } from 'core-app/features/hal/resources/hal-resource';
import type { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import type { WorkPackageChangeset } from 'core-app/features/work-packages/components/wp-edit/work-package-changeset';
import type { GroupDescriptor } from 'core-app/features/work-packages/components/wp-single-view/wp-single-view.component';
import type { WorkPackageAction } from 'core-app/features/work-packages/components/wp-table/context-menu-helper/wp-context-menu-helper.service';
import type { ResourceChangeset } from 'core-app/shared/components/fields/changeset/resource-changeset';
import type { WidgetRegistration } from 'core-app/shared/components/grids/grid/grid.component';

type ResourceChangesetClass = new (...params:ConstructorParameters<typeof ResourceChangeset>) => ResourceChangeset;

export interface HookSignatures {
  attributeGroupComponent:(group:GroupDescriptor, workPackage:WorkPackageResource) => Type<unknown>|null;
  gridWidgets:() => WidgetRegistration[];
  halResourceChangesetClass:(resource:HalResource) => ResourceChangesetClass|null;
  prependedAttributeGroups:(workPackage:WorkPackageResource) => Type<unknown>|undefined;
  workPackageAttachmentListComponent:(workPackage:WorkPackageResource) => Type<unknown>;
  workPackageAttachmentUploadComponent:(workPackage:WorkPackageResource) => Type<unknown>;
  workPackageBulkContextMenu:() => WorkPackageAction;
  workPackageNewInitialization:(change:WorkPackageChangeset) => void;
  workPackageSingleContextMenu:() => WorkPackageAction;
  workPackageTableContextMenu:() => WorkPackageAction;
}

type HookCallback = (...params:never[]) => unknown;

type CustomHookId<K extends string> = K extends keyof HookSignatures ? never : K;

@Injectable({
  providedIn: 'root',
})
export class HookService {
  private hooks:Record<string, HookCallback[]> = {};

  public register<K extends keyof HookSignatures>(id:K, callback:HookSignatures[K]):void;
  public register<K extends string>(id:CustomHookId<K>, callback:HookCallback):void;
  public register(id:string, callback:HookCallback) {
    if (!callback) {
      return;
    }

    if (!this.hooks[id]) {
      this.hooks[id] = [];
    }

    this.hooks[id].push(callback);
  }

  public call<K extends keyof HookSignatures>(
    id:K,
    ...params:Parameters<HookSignatures[K]>
  ):NonNullable<ReturnType<HookSignatures[K]>>[];

  public call<K extends string>(id:CustomHookId<K>, ...params:unknown[]):unknown[];
  public call(id:string, ...params:unknown[]):unknown[] {
    const results = [];

    if (this.hooks[id]) {
      for (const hook of this.hooks[id] as ((...params:unknown[]) => unknown)[]) {
        const result = hook(...params);

        if (result) {
          results.push(result);
        }
      }
    }

    return results;
  }
}

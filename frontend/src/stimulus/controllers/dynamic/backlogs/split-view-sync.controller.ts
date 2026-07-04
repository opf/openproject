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

import { Controller } from '@hotwired/stimulus';
import type { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { useAngularServices, type ServiceKey } from 'core-stimulus/mixins/use-angular-services';

// A split view open on a moved work package caches the lock_version it fetched
// on opening, so the next edit after a move would fail with a
// conflicting-modifications error. Every successful move is signalled via a
// document event, either dispatched by the server (cross-list moves) or by
// the client-side sortable-lists controller (same-list moves, which resolve
// with a 204 and never reach the server-dispatched event); this controller
// refreshes the moved work package in the Angular cache so the split view
// stays editable.
export default class SplitViewSyncController extends Controller {
  static services:ServiceKey[] = ['apiV3Service'];

  declare apiV3Service:ApiV3Service;

  initialize() {
    useAngularServices(this);
  }

  // Bound to the `op-dispatched:backlogs:work-package-moved` document event.
  // Refreshes a work package already in the cache. The most likely reason for this is that the
  // work package is or has been displayed in the split view. Refreshing prevents
  // the lock version becoming stale after move and also reflects the change to the sprint and
  // bucket property.
  // The method currently does not check if the work package is still open in the split view. If it
  // was ever opened, it will still be in the cache leading to a refresh request. The upside of this potentially
  // wasteful refresh is that when the work package is later on reopened in the split view, its information
  // is correct as well.
  onWorkPackageMoved(event:CustomEvent<{ work_package_id?:number }>):void {
    const workPackageId = event.detail?.work_package_id;
    if (workPackageId === undefined) { return; }
    this.refreshWorkPackage(workPackageId.toString());
  }

  // Bound to the client-dispatched `sortable-lists:moved` document event. Same
  // refresh as onWorkPackageMoved: optimistic same-list moves answer with 204,
  // so no server-dispatched moved event exists on that path. On cross-list
  // moves both events fire; the double refresh is idempotent.
  onSortableListsMoved(event:CustomEvent<{ itemId?:string }>):void {
    const itemId = event.detail?.itemId;
    if (itemId === undefined) { return; }
    this.refreshWorkPackage(itemId);
  }

  private refreshWorkPackage(id:string):void {
    // apiV3Service is wired asynchronously via useAngularServices, so it may be
    // absent if an event somehow fires before the services resolve.
    if (!this.apiV3Service) { return; }

    const { work_packages: workPackages } = this.apiV3Service;

    if (workPackages.cache.state(id).hasValue()) {
      void workPackages.id(id).refresh();
    }
  }
}

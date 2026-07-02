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
import { FrameElement } from '@hotwired/turbo';
import type { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { HalEventsService } from 'core-app/features/hal/services/hal-events.service';
import { filter, Subscription } from 'rxjs';

import { useAngularServices, type ServiceKey } from 'core-stimulus/mixins/use-angular-services';

// Dispatched by Backlogs::WorkPackagesController#move once a work package has been
// moved. Its detail carries the moved work package id.
const WORK_PACKAGE_MOVED_EVENT = 'op-dispatched:backlogs:work-package-moved';

export default class BacklogsController extends Controller<HTMLElement> {
  static services:ServiceKey[] = ['halEvents', 'apiV3Service'];
  declare halEvents:HalEventsService;
  declare apiV3Service:ApiV3Service;

  private subscription:Subscription|null = null;

  private readonly onWorkPackageMoved = (event:Event):void => {
    const { work_package_id: workPackageId } = (event as CustomEvent<{ work_package_id?:number }>).detail ?? {};
    if (workPackageId === undefined) { return; }

    // A split view open on the moved work package cached its lock_version on opening.
    // Refresh the cached resource so it picks up the new lock_version and stays editable.
    // The refresh only reaches a view actually subscribed to this id, so it is a no-op
    // for any other open view.
    void this.apiV3Service.work_packages.id(workPackageId.toString()).refresh();
  };

  initialize() {
    useAngularServices(this);
  }

  servicesConnected() {
    this.subscription = this.halEvents.aggregated$('WorkPackage')
      .pipe(filter((events) => events.some((event) => event.eventType === 'updated')))
      .subscribe(() => { this.refreshList(); });

    // Registered here rather than in connect() so apiV3Service is available by the
    // time the handler runs.
    document.addEventListener(WORK_PACKAGE_MOVED_EVENT, this.onWorkPackageMoved);
  }

  disconnect() {
    document.removeEventListener(WORK_PACKAGE_MOVED_EVENT, this.onWorkPackageMoved);
    this.subscription?.unsubscribe();
    this.subscription = null;
  }

  private refreshList() {
    void this.listElement.reload();
  }

  private get listElement() {
    return this.element.querySelector<FrameElement>('#backlogs_container')!;
  }
}

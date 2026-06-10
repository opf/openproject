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
import type { FrameElement } from '@hotwired/turbo';
import { filter, Subscription } from 'rxjs';
import type { HalEventsService } from 'core-app/features/hal/services/hal-events.service';
import { useServices, type ServiceKey } from 'core-stimulus/mixins/use-services';

// The Backlogs lists are server-rendered and updated via Turbo streams on drag
// moves, but a work package can also change outside a drag — e.g. edited in the
// split pane or by the Angular layer. Those edits emit HAL events rather than a
// Turbo stream targeting this frame, so subscribe to them and reload the frame
// to keep the cards (and sprint point totals) in sync.
//
// Declared on the turbo-frame tag itself, so `this.element` is the frame.
export default class ListRefreshController extends Controller<FrameElement> {
  static services:ServiceKey[] = ['halEvents'];

  declare halEvents:HalEventsService;

  private subscription:Subscription|null = null;

  initialize() {
    useServices(this);
  }

  servicesConnected() {
    this.subscription = this.halEvents
      .aggregated$('WorkPackage')
      .pipe(filter((events) => events.some((event) => event.eventType === 'updated')))
      .subscribe(() => { void this.element.reload(); });
  }

  disconnect() {
    this.subscription?.unsubscribe();
    this.subscription = null;
  }
}

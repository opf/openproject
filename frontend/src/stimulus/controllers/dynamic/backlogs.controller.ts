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
import { HalEventsService } from 'core-app/features/hal/services/hal-events.service';
import { filter, Subscription } from 'rxjs';

import { useAngularServices, type ServiceKey } from 'core-stimulus/mixins/use-angular-services';

// The work package detail/side panel renders into this shared turbo frame.
const SPLIT_VIEW_FRAME_ID = 'content-bodyRight';

// The backlog is scrolled by `#content`, or by `#content-body` while the side
// panel is open (see frontend/.../layout/_base.sass). Only one is scrollable at
// a time, so we resolve whichever currently is.
const SCROLL_CONTAINER_IDS = ['content-body', 'content'];

export default class BacklogsController extends Controller<HTMLElement> {
  static services:ServiceKey[] = ['halEvents'];
  declare halEvents:HalEventsService;

  private subscription:Subscription|null = null;
  private abortController:AbortController|null = null;
  private savedScrollTop = 0;

  initialize() {
    useAngularServices(this);
  }

  connect() {
    this.abortController = new AbortController();
    const { signal } = this.abortController;

    // Opening or closing the side panel navigates the content-bodyRight turbo
    // frame, which otherwise resets the backlog to the top and loses the user's
    // refinement spot (AGILE-241). We snapshot the scroll position before the
    // frame renders and reapply it afterwards.
    const frame = document.getElementById(SPLIT_VIEW_FRAME_ID);
    frame?.addEventListener('turbo:before-frame-render', this.rememberScrollPosition, { signal });
    frame?.addEventListener('turbo:frame-render', this.restoreScrollPosition, { signal });
  }

  servicesConnected() {
    this.subscription = this.halEvents.aggregated$('WorkPackage')
      .pipe(filter((events) => events.some((event) => event.eventType === 'updated')))
      .subscribe(() => { this.refreshList(); });
  }

  disconnect() {
    this.subscription?.unsubscribe();
    this.subscription = null;

    this.abortController?.abort();
    this.abortController = null;
    this.savedScrollTop = 0;
  }

  private refreshList() {
    void this.listElement.reload();
  }

  private rememberScrollPosition = ():void => {
    this.savedScrollTop = this.scrollContainer?.scrollTop ?? 0;
  };

  private restoreScrollPosition = ():void => {
    const target = this.savedScrollTop;
    if (target <= 0) {
      return;
    }

    const apply = () => {
      const container = this.scrollContainer;
      if (container) { container.scrollTop = target; }
    };

    // The frame navigation is promoted to a turbo visit that scrolls after the
    // frame renders, so reapply once the layout has settled (the ~25ms mirrors
    // keep-scroll-position.controller.ts).
    apply();
    window.setTimeout(apply, 25);
  };

  // The container the backlog currently scrolls in: whichever candidate is
  // actually scrollable. `#content` reports `overflow: hidden` while the side
  // panel is open, so it is skipped in favour of `#content-body`.
  private get scrollContainer():HTMLElement|null {
    return SCROLL_CONTAINER_IDS
      .map((id) => document.getElementById(id))
      .find((el):el is HTMLElement => (
        el !== null && ['auto', 'scroll'].includes(window.getComputedStyle(el).overflowY)
      )) ?? null;
  }

  private get listElement() {
    return this.element.querySelector<FrameElement>('#backlogs_container')!;
  }
}

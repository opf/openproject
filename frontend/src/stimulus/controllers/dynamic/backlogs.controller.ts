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

// Depending on whether the side panel is shown, the backlog is scrolled either
// by `#content` or by `#content-body` (see frontend/.../layout/_base.sass). We
// read the position from whichever container is currently scrollable and write
// it back to both so it survives the container switch.
const SCROLL_CONTAINER_IDS = ['content-body', 'content'];

export default class BacklogsController extends Controller<HTMLElement> {
  static services:ServiceKey[] = ['halEvents'];
  declare halEvents:HalEventsService;

  private subscription:Subscription|null = null;
  private abortController:AbortController|null = null;
  private savedScrollTop:number|null = null;

  initialize() {
    useAngularServices(this);
  }

  connect() {
    this.abortController = new AbortController();
    const { signal } = this.abortController;

    const frame = this.splitViewFrame;
    if (frame) {
      // Opening or closing the side panel navigates the content-bodyRight turbo
      // frame. Without this, each navigation resets the backlog to the top and
      // the user loses their refinement spot (AGILE-241). We snapshot the scroll
      // position before the frame renders and reapply it afterwards.
      frame.addEventListener('turbo:before-frame-render', this.rememberScrollPosition, { signal });
      frame.addEventListener('turbo:frame-render', this.restoreScrollPosition, { signal });
    }
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
    this.savedScrollTop = null;
  }

  private refreshList() {
    void this.listElement.reload();
  }

  private rememberScrollPosition = ():void => {
    // Only the container that is actually scrollable in the current split state
    // tracks the user's position. While the panel is open `#content` becomes
    // `overflow: hidden` but keeps a stale, possibly larger `scrollTop`; reading
    // the max across both would resurface that outdated position on the next
    // open/close. So we read from the active scroll container only.
    this.savedScrollTop = this.activeScrollContainer?.scrollTop ?? null;
  };

  private restoreScrollPosition = ():void => {
    const target = this.savedScrollTop;
    this.savedScrollTop = null;

    if (target === null || target <= 0) {
      return;
    }

    const apply = () => {
      // Setting scrollTop on the currently inactive (non-scrollable) container
      // is a harmless no-op, so we can apply to both candidates unconditionally.
      this.scrollContainers.forEach((container) => { container.scrollTop = target; });
    };

    apply();
    // Reapply once layout has settled. The frame navigation is promoted to a
    // turbo visit which scrolls afterwards, so a single synchronous write is
    // not always enough (mirrors the keep-scroll-position controller).
    requestAnimationFrame(apply);
    window.setTimeout(apply, 25);
  };

  private get scrollContainers():HTMLElement[] {
    return SCROLL_CONTAINER_IDS
      .map((id) => document.getElementById(id))
      .filter((element):element is HTMLElement => element !== null);
  }

  // The container the user is actually scrolling: the first candidate whose
  // computed overflow allows scrolling. `#content` reports `overflow: hidden`
  // while the side panel is open, so it is skipped in favour of `#content-body`.
  private get activeScrollContainer():HTMLElement|null {
    return this.scrollContainers.find((container) => {
      const { overflowY } = window.getComputedStyle(container);
      return overflowY === 'auto' || overflowY === 'scroll';
    }) ?? null;
  }

  private get splitViewFrame() {
    return document.getElementById(SPLIT_VIEW_FRAME_ID);
  }

  private get listElement() {
    return this.element.querySelector<FrameElement>('#backlogs_container')!;
  }
}

/*
 * -- copyright
 * OpenProject is an open source project management software.
 * Copyright (C) 2023 the OpenProject GmbH
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License version 3.
 *
 * OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
 * Copyright (C) 2006-2013 Jean-Philippe Lang
 * Copyright (C) 2010-2013 the ChiliProject Team
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 *
 * See COPYRIGHT and LICENSE files for more details.
 * ++
 */

export interface ViewPortServiceInterface {
  isMobile():boolean;
  isWithinNotificationCenter():boolean;
  isWithinSplitScreen():boolean;
  isJournalsContainerScrolledToBottom():boolean;
  scrollableContainer:HTMLElement | null;
  anchorScrollOffset():number;
}

export class ViewPortService implements ViewPortServiceInterface {
  // Small gap kept above a comment reached by its anchor so it seats just below
  // the connector stem (or, on mobile, just below the pinned toolbar) instead of
  // exposing the bottom of the previous comment above it.
  private static readonly ANCHOR_SCROLL_GAP = 16;

  private notificationCenterPathName:string;
  private splitScreenPathName:string;

  private mobileBreakpoint:number;
  private mobileBreakpointInNotificationCenter:number;

  constructor(
    notificationCenterPathName = 'notifications',
    splitScreenPathName = 'work_packages/details',
    mobileBreakpoint = 1279,
    mobileBreakpointInNotificationCenter = 1013,
  ) {
    this.notificationCenterPathName = notificationCenterPathName;
    this.splitScreenPathName = splitScreenPathName;
    this.mobileBreakpoint = mobileBreakpoint;
    this.mobileBreakpointInNotificationCenter = mobileBreakpointInNotificationCenter;
  }

  isMobile():boolean {
    if (this.isWithinNotificationCenter() || this.isWithinSplitScreen()) {
      return window.innerWidth < this.mobileBreakpointInNotificationCenter;
    }
    return window.innerWidth < this.mobileBreakpoint;
  }

  isWithinNotificationCenter():boolean {
    return window.location.pathname.includes(this.notificationCenterPathName);
  }

  isWithinSplitScreen():boolean {
    return window.location.pathname.includes(this.splitScreenPathName);
  }

  isJournalsContainerScrolledToBottom():boolean {
    let atBottom = false;
    // we have to handle different scrollable containers for different viewports/pages in order to idenfity if the user is at the bottom of the journals
    // DOM structure different for notification center and workpackage detail view as well
    const scrollableContainer = this.scrollableContainer;
    if (scrollableContainer) {
      atBottom = (scrollableContainer.scrollTop + scrollableContainer.clientHeight + 10) >= scrollableContainer.scrollHeight;
    }

    return atBottom;
  }

  get scrollableContainer():HTMLElement | null {
    if (this.isWithinNotificationCenter() || this.isWithinSplitScreen()) {
      // valid for both mobile and desktop
      return document.querySelector('.work-package-details-tab')!;
    }
    if (this.isMobile()) {
      return document.querySelector('#content-body')!;
    }

    // valid for desktop
    return document.querySelector('.tabcontent')!;
  }

  // How far down to seat a comment scrolled to via its anchor: just below any
  // header pinned to the top of the scroll container (the work package toolbar on
  // mobile), plus a small gap. Desktop pins nothing there, so the comment seats a
  // gap below the top, showing only the connector stem above it rather than the
  // previous comment.
  anchorScrollOffset():number {
    const container = this.scrollableContainer;
    const pinnedHeader = container ? this.pinnedHeaderHeight(container) : 0;

    return pinnedHeader + ViewPortService.ANCHOR_SCROLL_GAP;
  }

  // Height of any header pinned to the top of the container, read from the live
  // paint stack because the toolbar's height is not fixed:
  //
  //   ┌─ pinned toolbar ─┐  ← container top
  //   ├──────────────────┤  ← returned height; the comment seats below this line
  //   │  journals …      │
  //
  private pinnedHeaderHeight(container:HTMLElement):number {
    const containerRect = container.getBoundingClientRect();
    const probeX = containerRect.left + (container.clientWidth / 2);
    const stack = document.elementsFromPoint(probeX, containerRect.top + 1);

    let height = 0;
    for (const node of stack) {
      if (node === container || !container.contains(node)) { continue; }

      // Only a sticky header is pinned relative to this container. A fixed
      // element is positioned against the viewport, so its position over the
      // container top is incidental and must not reserve space here.
      const { position } = window.getComputedStyle(node);
      if (position === 'sticky') {
        height = Math.max(height, node.getBoundingClientRect().bottom - containerRect.top);
      }
    }

    return height;
  }
}

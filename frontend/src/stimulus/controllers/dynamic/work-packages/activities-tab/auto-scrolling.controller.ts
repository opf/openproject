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

import BaseController from './base.controller';
import { UrlHelpers, ActivityAnchorType, ActivityAnchor } from './services/url-helpers';

interface CustomEventWithIdParam extends Event {
  params:{
    id:string;
    anchorName:ActivityAnchorType;
  };
}

export default class AutoScrollingController extends BaseController {
  static values = {
    resolvedCommentId: Number,
  };

  declare readonly resolvedCommentIdValue:number;
  declare readonly hasResolvedCommentIdValue:boolean;

  private abortController!:AbortController;

  connect() {
    super.connect();

    // Construct per connect so a disconnect→reconnect of the same instance gets a
    // fresh signal; an already-aborted one would silently drop these listeners.
    this.abortController = new AbortController();

    window.addEventListener('hashchange', this.scrollToHashAnchor, { signal: this.abortController.signal });
    this.element.addEventListener('click', this.handleCommentReferenceClick, { signal: this.abortController.signal });
    this.handleInitialScroll();
  }

  disconnect() {
    this.abortController.abort();
  }

  setAnchor(event:CustomEventWithIdParam) {
    // Suppress the link's native jump and let the resulting hash change drive the
    // scroll and highlight, so a click here behaves like any other anchor change.
    event.preventDefault();
    window.location.hash = `#${event.params.anchorName}-${event.params.id}`;
  }

  performAutoScrollingOnStreamsUpdate(journalsContainerAtBottom = false) {
    if (this.indexOutlet.sortingAscending && journalsContainerAtBottom) {
      // scroll to (new) bottom if sorting is ascending and journals container was already at bottom before a new activity was added
      if (this.isMobile()) {
        this.scrollInputContainerIntoView(300);
      } else {
        this.scrollJournalContainer(true, true);
      }
    }
  }

  performAutoScrollingOnFormSubmit() {
    if (this.isMobile() && !this.isWithinNotificationCenter()) {
      // wait for the keyboard to be fully down before scrolling further
      // timeout amount tested on mobile devices for best possible user experience
      this.scrollInputContainerIntoView(800);
    } else {
      this.scrollJournalContainer(this.indexOutlet.sortingAscending, true);
    }
  }

  scrollInputContainerIntoView(timeout = 0, behavior:ScrollBehavior = 'smooth') {
    const inputContainer = this.inputContainer;
    setTimeout(() => {
      if (inputContainer) {
        inputContainer.scrollIntoView({
          behavior,
          block: this.indexOutlet.sortingDescending ? 'nearest' : 'start',
        });
      }
    }, timeout);
  }

  scrollJournalContainer(toBottom:boolean, smooth = false) {
    const scrollableContainer = this.scrollableContainer;
    if (scrollableContainer) {
      if (smooth) {
        scrollableContainer.scrollTo({
          top: toBottom ? scrollableContainer.scrollHeight : 0,
          behavior: 'smooth',
        });
      } else {
        scrollableContainer.scrollTop = toBottom ? scrollableContainer.scrollHeight : 0;
      }
    }
  }

  private handleInitialScroll() {
    const anchorInfo = UrlHelpers.extractActivityAnchor(window.location.hash);

    if (anchorInfo) {
      const anchor = this.canonicalizeActivityAnchor(anchorInfo);
      // A still-legacy activity anchor is one the server could not resolve to a
      // comment; no element carries it anymore, so there is nothing to scroll to.
      if (anchor.type === ActivityAnchorType.Activity) { return; }

      const activityElement = this.getActivityAnchorElement(anchor);
      this.brieflyHighlightAndResetUrl(activityElement, window.location.hash);
      this.scrollToActivity(activityElement);
    } else if (this.indexOutlet.sortingAscending && (!this.isMobile() || this.isWithinNotificationCenter())) {
      this.scrollToBottom();
    }
  }

  // Reacts to any hash change without a fresh render: a comment timestamp click,
  // an in-page comment link, or editing the comment id in the URL. Initial-load
  // scrolling stays in handleInitialScroll, which waits for not-yet-rendered content.
  private scrollToHashAnchor = () => {
    const anchorInfo = UrlHelpers.extractActivityAnchor(window.location.hash);
    // Only a comment anchor maps to a rendered element. A legacy activity-N anchor
    // is resolved to its comment by the server when the page loads with ?anchor;
    // a hash change makes no such request, so there is nothing to scroll to.
    if (anchorInfo?.type !== ActivityAnchorType.Comment) { return; }

    const activityElement = this.getActivityAnchorElement(anchorInfo);
    const scrollableContainer = this.scrollableContainer;
    if (!activityElement || !scrollableContainer) { return; }

    // Successive hash changes happen without a reload, so drop a previous
    // highlight before applying the new one instead of stacking them.
    this.clearAnchorHighlight();
    this.brieflyHighlightAndResetUrl(activityElement, window.location.hash);

    // offsetTop is relative to the element's offsetParent, which is not the
    // scroll container, so measure the gap between the two directly, then back
    // the target off so the comment lands below the pinned header, not behind it.
    const relativeTop = activityElement.getBoundingClientRect().top
      - scrollableContainer.getBoundingClientRect().top;
    scrollableContainer.scrollTo({
      top: scrollableContainer.scrollTop + relativeTop - this.anchorScrollOffset(),
      behavior: 'smooth',
    });
  };

  // In-content comment references are plain links inside the activities frame, so
  // Turbo would treat a click as a frame/page visit and drop the fragment. When a
  // link points to a comment on this very page, drive it through the hash instead
  // and let scrollToHashAnchor take over; anything else navigates as usual.
  private handleCommentReferenceClick = (event:MouseEvent) => {
    // Respect already-handled clicks (e.g. the timestamp link) and new-tab intents.
    if (event.defaultPrevented || event.button !== 0
      || event.metaKey || event.ctrlKey || event.shiftKey || event.altKey) { return; }

    const link = (event.target as HTMLElement).closest('a[href]');
    if (!link) { return; }

    const anchor = this.sameActivityPageCommentAnchor(link as HTMLAnchorElement);
    // Only claim the click when the comment is rendered here; otherwise let it
    // navigate, so a link to a comment on another page (or filtered view) is not
    // swallowed into a hash change that resolves to nothing.
    if (!anchor || !this.getActivityAnchorElement(anchor)) { return; }

    event.preventDefault();
    window.location.hash = `#${anchor.type}-${anchor.id}`;
  };

  private sameActivityPageCommentAnchor(link:HTMLAnchorElement):ActivityAnchor | null {
    const target = new URL(link.href, window.location.href);
    if (target.origin !== window.location.origin || target.pathname !== window.location.pathname) {
      return null;
    }

    const anchor = UrlHelpers.extractActivityAnchor(target.hash);
    return anchor?.type === ActivityAnchorType.Comment ? anchor : null;
  }

  private canonicalizeActivityAnchor(anchorInfo:ActivityAnchor):ActivityAnchor {
    const resolvedCommentId = this.hasResolvedCommentIdValue ? this.resolvedCommentIdValue : null;
    const canonical = UrlHelpers.canonicalActivityAnchor(anchorInfo, resolvedCommentId);

    if (canonical.type !== anchorInfo.type || canonical.id !== anchorInfo.id) {
      // Rewrite via the full href: a bare "#…" would resolve against the page's
      // <base href> and drop the work package path.
      const url = new URL(window.location.href);
      url.hash = `${canonical.type}-${canonical.id}`;
      window.history.replaceState(null, '', url);
    }

    return canonical;
  }

  private scrollToActivity(activityElement:HTMLElement|null) {
    const maxAttempts = 20; // wait max 20 seconds for the activity to be rendered
    this.tryScroll(activityElement, 0, maxAttempts);
  }

  private scrollToBottom() {
    this.tryScrollToBottom(0, 20, 'auto');
  }

  private tryScroll(activityElement:HTMLElement|null, attempts:number, maxAttempts:number) {
    const scrollableContainer = this.scrollableContainer;

    if (activityElement && scrollableContainer) {
      scrollableContainer.scrollTop = 0;

      setTimeout(() => {
        const containerRect = scrollableContainer.getBoundingClientRect();
        const elementRect = activityElement.getBoundingClientRect();
        const relativeTop = elementRect.top - containerRect.top;

        scrollableContainer.scrollTop = relativeTop - this.anchorScrollOffset();
      }, 50);
    } else if (attempts < maxAttempts) {
      setTimeout(() => {
        this.tryScroll(activityElement, attempts + 1, maxAttempts);
      }, 1000);
    }
  }

  private tryScrollToBottom(attempts = 0, maxAttempts = 20, behavior:ScrollBehavior = 'smooth') {
    const scrollableContainer = this.scrollableContainer;

    if (!scrollableContainer) {
      if (attempts < maxAttempts) {
        setTimeout(() => {
          this.tryScrollToBottom(attempts + 1, maxAttempts);
        }, 1000);
      }
      return;
    }

    scrollableContainer.scrollTop = 0;

    let timeoutId:ReturnType<typeof setTimeout>;

    const observer = new MutationObserver(() => {
      clearTimeout(timeoutId);

      timeoutId = setTimeout(() => {
        observer.disconnect();
        scrollableContainer.scrollTo({
          top: scrollableContainer.scrollHeight,
          behavior,
        });
      }, 100);
    });

    observer.observe(scrollableContainer, {
      childList: true,
      subtree: true,
      attributes: true,
    });
  }

  private clearAnchorHighlight() {
    this.element
      .querySelectorAll('.--anchor-highlighted')
      .forEach((highlighted) => highlighted.classList.remove('--anchor-highlighted'));
  }

  private brieflyHighlightAndResetUrl(activityElement:HTMLElement|null, locationHash:string) {
    if (activityElement) {
      activityElement.classList.add('--anchor-highlighted');
      setTimeout(() => {
        document.addEventListener('click', () => {
          activityElement.classList.remove('--anchor-highlighted');
          const newLocation = window.location.href.replace(locationHash, '');
          window.history.replaceState(null, 'Remove anchor', newLocation);
        }, { once: true, signal: this.abortController.signal });
      });
    }
  }

  private getActivityAnchorElement(activityAnchor:ActivityAnchor):HTMLElement | null {
    // Scope to this controller's own activities frame: the window-level hashchange
    // listener fires on every controller, and each must only claim its own comments.
    return this.element.querySelector(`[data-anchor-${activityAnchor.type}-id="${activityAnchor.id}"]`);
  }

  private get inputContainer():HTMLElement | null {
    return this.element.querySelector('.work-packages-activities-tab-journals-new-component');
  }

  isJournalsContainerScrolledToBottom():boolean {
    let atBottom = false;
    // we have to handle different scrollable containers for different viewports/pages in order to identify if the user is at the bottom of the journals
    // DOM structure different for notification center and workpackage detail view as well
    const scrollableContainer = this.scrollableContainer;
    if (scrollableContainer) {
      atBottom = (scrollableContainer.scrollTop + scrollableContainer.clientHeight + 10) >= scrollableContainer.scrollHeight;
    }

    return atBottom;
  }
}

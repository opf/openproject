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

// Mirrors Backlogs::WorkPackageCardComponent::FRAME_ID_SUFFIX: the suffix every
// work package card turbo-frame id ends with.
const CARD_FRAME_SUFFIX = '_card';

export default class BacklogsController extends Controller<HTMLElement> {
  static services:ServiceKey[] = ['halEvents'];
  declare halEvents:HalEventsService;

  private subscription:Subscription|null = null;
  private abortController:AbortController|null = null;

  initialize() {
    useAngularServices(this);
  }

  connect() {
    this.abortController = new AbortController();
    document.addEventListener(
      'turbo:before-morph-element',
      this.reloadCardFrameOnMorph,
      { signal: this.abortController.signal },
    );
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
  }

  // Work package cards are lazily loaded turbo-frames whose `src` carries a hash
  // of the card's state (e.g. status, parent and type). The server response carries
  // a skeleton which is only to be shown on the initial load. Morphing the list would
  // replace an already loaded card with its skeleton placeholder, so instead we prevent
  // the morph and reload the frame. A reload keeps the current content visible until the response
  // swaps in, so the skeleton never reappears; for an unchanged card the
  // response comes from the (immutable) browser cache and is imperceptible, and
  // re-rendering also rebuilds the deferred menu so it cannot go stale.
  private reloadCardFrameOnMorph = (event:Event):void => {
    const morphEvent = event as CustomEvent<{ newElement:Element }>;
    const frame = morphEvent.target as Element;
    if (!this.isLoadedCardFrame(frame)) { return; }

    morphEvent.preventDefault();

    const newSrc = morphEvent.detail.newElement?.getAttribute('src');
    if (newSrc && !frame.getAttribute('src')?.endsWith(newSrc)) {
      // The server reports a different state: point the frame at the new URL,
      // which reloads it from there.
      frame.setAttribute('src', newSrc);
    } else {
      // Same state: reload the (cache-served) URL to refresh the card and its
      // menu without a perceptible change.
      void (frame as FrameElement).reload();
    }
  };

  private isLoadedCardFrame(element:Element):boolean {
    return element.tagName === 'TURBO-FRAME'
      && element.id.endsWith(CARD_FRAME_SUFFIX)
      && element.hasAttribute('complete');
  }

  private refreshList() {
    void this.listElement.reload();
  }

  private get listElement() {
    return this.element.querySelector<FrameElement>('#backlogs_container')!;
  }
}

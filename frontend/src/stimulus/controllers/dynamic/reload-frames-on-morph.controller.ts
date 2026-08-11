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

import { Controller } from '@hotwired/stimulus';
import { FrameElement } from '@hotwired/turbo';

// Reusable behaviour for lazily loaded turbo-frames whose `src` carries a hash
// of the rendered state. When the surrounding content is morphed, replacing an
// already loaded frame with its server-rendered skeleton placeholder would
// flicker and discard any deferred content (e.g. an opened menu). Instead, for
// each frame registered as a `frame` target, we prevent the morph and reload
// the frame:
//
// * the current content stays visible until the response swaps in, so the
//   skeleton never reappears.
// * an unchanged frame is reloaded. Ideally, the frame is served from browser
//   cache so that the operation does not trigger a network request, but this is
//   not guaranteed by this controller.
// * a changed frame is pointed at its new `src`, which reloads it from there.
//
// Attach the controller to an element containing the frames and mark each frame
// with `data-reload-frames-on-morph-target="frame"`.
export default class ReloadFramesOnMorphController extends Controller<HTMLElement> {
  static targets = ['frame'];

  declare readonly frameTargets:FrameElement[];

  private abortController:AbortController|null = null;

  connect() {
    this.abortController = new AbortController();
    // turbo:before-morph-element bubbles, so listening on the controller's
    // element scopes us to the frames it contains.
    this.element.addEventListener(
      'turbo:before-morph-element',
      this.reloadFrameOnMorph,
      { signal: this.abortController.signal },
    );
  }

  disconnect() {
    this.abortController?.abort();
    this.abortController = null;
  }

  private reloadFrameOnMorph = (event:Event):void => {
    const morphEvent = event as CustomEvent<{ newElement:Element }>;
    const frame = morphEvent.target as Element;
    if (!(frame instanceof FrameElement) ||
      !this.frameTargets.includes(frame) ||
      !frame.hasAttribute('complete') ||
      !morphEvent.detail.newElement) {
      return;
    }

    morphEvent.preventDefault();

    const newSrc = morphEvent.detail.newElement.getAttribute('src');
    if (newSrc && !frame.getAttribute('src')?.endsWith(newSrc)) {
      frame.setAttribute('src', newSrc);
    }
  };
}

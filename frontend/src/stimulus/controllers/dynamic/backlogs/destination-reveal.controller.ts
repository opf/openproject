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
// along with this program. If not, see <https://www.gnu.org/licenses/>.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { Controller } from '@hotwired/stimulus';
import type { StreamElement } from '@hotwired/turbo';

interface Destination {
  list_type:string;
  list_id:number|null;
}

interface MovedDetail {
  work_package_ids?:number[];
  work_package_id?:number;
  destination_changed?:boolean;
  destination?:Destination;
}

interface RevealFrame {
  requested:boolean;
  complete:boolean;
  pending?:{ id:string; destination:Destination };
}

export default class DestinationRevealController extends Controller<HTMLElement> {
  static targets = ['card'];

  declare readonly cardTargets:HTMLElement[];

  private frame?:RevealFrame;
  private animationFrame:number|null = null;

  disconnect():void {
    this.reset();
  }

  onBeforeStreamRender(event:CustomEvent<{ newStream:StreamElement }>):void {
    const stream = event.detail.newStream;
    if (stream.getAttribute('action') !== 'turbo_frame_reload' || stream.getAttribute('target') !== this.element.id) return;

    this.reset();
    this.frame = { requested: false, complete: false };
  }

  onFrameRequest(event:Event):void {
    if (event.target !== this.element) return;
    if (this.frame && !this.frame.requested) this.frame.requested = true;
    else this.reset();
  }

  onFrameResponse(event:CustomEvent<{ fetchResponse:{ succeeded:boolean } }>):void {
    if (event.target === this.element && !event.detail.fetchResponse.succeeded) this.reset();
  }

  onFrameFailed(event:Event):void {
    if (event.target === this.element) this.reset();
  }

  onFrameLoad(event:Event):void {
    if (event.target !== this.element || !this.frame?.requested) return;
    this.frame.complete = true;
    if (this.frame.pending) this.scheduleReveal();
  }

  onWorkPackageMoved(event:CustomEvent<MovedDetail>):void {
    this.cancelScheduled();
    const { destination_changed: changed, destination } = event.detail;
    const id = event.detail.work_package_ids?.[0] ?? event.detail.work_package_id;
    if (!this.frame || changed !== true || !destination || id === undefined) {
      this.reset();
      return;
    }

    this.frame.pending = { id: String(id), destination };
    if (this.frame.complete) this.scheduleReveal();
  }

  revealPending():void {
    const pending = this.frame?.pending;
    this.reset();
    if (!pending || !this.element.isConnected) return;

    const card = this.cardTargets.find((candidate) => {
      if (candidate.getAttribute('data-backlogs--work-package-id-value') !== pending.id) return false;
      const list = candidate.closest('[data-controller~="sortable-lists--list"]');
      return list?.getAttribute('data-sortable-lists--list-type-value') === pending.destination.list_type
        && (list.getAttribute('data-sortable-lists--list-id-value') ?? '') === (pending.destination.list_id?.toString() ?? '');
    });
    card?.scrollIntoView({ block: 'nearest', inline: 'nearest' });
  }

  private scheduleReveal():void {
    this.cancelScheduled();
    const frame = this.frame;
    this.animationFrame = requestAnimationFrame(() => {
      this.animationFrame = requestAnimationFrame(() => {
        this.animationFrame = null;
        if (this.frame === frame) this.revealPending();
      });
    });
  }

  private cancelScheduled():void {
    if (this.animationFrame !== null) cancelAnimationFrame(this.animationFrame);
    this.animationFrame = null;
  }

  private reset():void {
    this.cancelScheduled();
    this.frame = undefined;
  }
}

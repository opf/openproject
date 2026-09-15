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

import type AnchoredPositionElement from '@openproject/primer-view-components/app/components/primer/anchored_position';
import { render } from 'lit-html';
import type { Timeline } from 'vis-timeline/standalone';
import type { ProjectTimelineTooltipBuilder, TooltipView } from './project-timeline-tooltip.builder';
import { caretPlacement } from './project-timeline-tooltip-caret';

const TOOLTIP_DELAY_IN_MS = 500;

const EMPTY_VIEW:TooltipView = { anchor: null, content: null, caret: null };

interface VisItem {
  getTitle():HTMLElement | string | undefined;
}

interface VisItemSet {
  getItemById(id:string):VisItem | undefined;
}

interface ItemHoverEvent {
  item:string;
  event:MouseEvent;
}

// vis-timeline renders its own tooltip inside the timeline root, where the
// dashboard grid cell (`.grid--area`, `overflow: hidden` + `z-index`) clips
// it. A popover in the top layer escapes both. It stays a child of the
// `aria-hidden` container so the sr-only list remains the only accessible
// representation.
// https://community.openproject.org/wp/SPPM-324
export class ProjectTimelineTooltipPopover {
  private readonly host = document.createElement('div');
  private view:TooltipView = EMPTY_VIEW;
  private timer:number | null = null;
  private readonly onItemOver = (props:ItemHoverEvent) => this.show(props);
  private readonly onLeave = () => this.hide();
  private readonly onViewportChange = () => this.hide();

  constructor(
    private readonly timeline:Timeline,
    container:HTMLElement,
    private readonly builder:ProjectTimelineTooltipBuilder,
  ) {
    container.appendChild(this.host);
    this.render();

    timeline.on('itemover', this.onItemOver);
    timeline.on('itemout', this.onLeave);
    timeline.on('rangechange', this.onLeave);
    document.addEventListener('scroll', this.onViewportChange, { capture: true, passive: true });
    window.addEventListener('resize', this.onViewportChange);
  }

  hide():void {
    this.clearTimer();
    if (this.popover?.isConnected) this.popover.togglePopover(false);
    this.view = EMPTY_VIEW;
    this.render();
  }

  destroy():void {
    this.hide();
    this.timeline.off('itemover', this.onItemOver);
    this.timeline.off('itemout', this.onLeave);
    this.timeline.off('rangechange', this.onLeave);
    document.removeEventListener('scroll', this.onViewportChange, { capture: true });
    window.removeEventListener('resize', this.onViewportChange);
    this.host.remove();
  }

  private show({ item, event }:ItemHoverEvent):void {
    const anchor = event.target instanceof Element ? this.anchorFor(event.target) : null;
    const content = this.visItemSet()?.getItemById(item)?.getTitle();
    if (!anchor || !content) {
      this.hide();
      return;
    }

    this.view = { anchor, content, caret: null };
    this.render();

    this.clearTimer();
    this.timer = window.setTimeout(() => {
      this.timer = null;
      this.open(anchor);
    }, TOOLTIP_DELAY_IN_MS);
  }

  // `anchored-position` positions the popover in a frame it requests on
  // `beforetoggle` and does not report which side it settled on, so the caret
  // is derived from the resulting geometry one frame after opening.
  private open(anchor:HTMLElement):void {
    if (!anchor.isConnected) return;

    this.popover?.togglePopover(true);
    requestAnimationFrame(() => this.alignCaret());
  }

  private alignCaret():void {
    const popover = this.popover;
    const { anchor } = this.view;
    if (!popover || !anchor || !popover.matches(':popover-open')) return;

    this.view = { ...this.view, caret: caretPlacement(popover.getBoundingClientRect(), anchor.getBoundingClientRect()) };
    this.render();
  }

  // Point items carry their marker in a nested `.vis-dot`; milestones draw the
  // diamond there while gates hide it and draw an icon in the content instead.
  private anchorFor(target:Element):HTMLElement | null {
    const item = target.closest<HTMLElement>('.vis-item');
    const dot = item?.querySelector<HTMLElement>('.vis-dot');
    return (dot?.getClientRects().length ? dot : item) ?? null;
  }

  private render():void {
    render(this.builder.popoverTemplate(this.view), this.host);
  }

  private get popover():AnchoredPositionElement | null {
    return this.host.querySelector<AnchoredPositionElement>('anchored-position');
  }

  private clearTimer():void {
    if (this.timer !== null) {
      window.clearTimeout(this.timer);
      this.timer = null;
    }
  }

  private visItemSet():VisItemSet | undefined {
    return (this.timeline as unknown as { itemSet?:VisItemSet }).itemSet;
  }
}

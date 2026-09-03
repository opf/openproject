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

import '@openproject/primer-view-components/app/components/primer/anchored_position';
import { html } from 'lit-html';
import type { Timeline } from 'vis-timeline/standalone';
import { ProjectTimelineTooltipPopover } from './project-timeline-tooltip.popover';
import type { ProjectTimelineTooltipBuilder, TooltipView } from './project-timeline-tooltip.builder';

type Handler = (props?:unknown) => void;

class TimelineStub {
  readonly handlers = new Map<string, Set<Handler>>();
  readonly itemSet = { getItemById: () => ({ getTitle: () => 'Launch' }) };

  on(event:string, handler:Handler):void {
    this.handlers.set(event, (this.handlers.get(event) ?? new Set()).add(handler));
  }

  off(event:string, handler:Handler):void {
    this.handlers.get(event)?.delete(handler);
  }

  emit(event:string, props?:unknown):void {
    this.handlers.get(event)?.forEach((handler) => handler(props));
  }

  get registered():number {
    return [...this.handlers.values()].reduce((sum, set) => sum + set.size, 0);
  }
}

describe('ProjectTimelineTooltipPopover', () => {
  let container:HTMLElement;
  let item:HTMLElement;
  let timeline:TimelineStub;

  const builder = {
    popoverTemplate: ({ anchor, content }:TooltipView) => html`
      <anchored-position popover="manual" side="outside-top" align="center" .anchorElement=${anchor}>
        <div class="Popover-message">${content}</div>
      </anchored-position>
    `,
  } as unknown as ProjectTimelineTooltipBuilder;

  const popover = () => container.querySelector<HTMLElement>('anchored-position');
  const hoverItem = () => timeline.emit('itemover', { item: 'm1', event: { target: item } });

  beforeEach(() => {
    vi.useFakeTimers({ toFake: ['setTimeout', 'clearTimeout'] });
    container = document.createElement('div');
    item = document.createElement('div');
    item.className = 'vis-item';
    container.append(item);
    document.body.append(container);
    timeline = new TimelineStub();
  });

  afterEach(() => {
    vi.useRealTimers();
    container.remove();
  });

  it('listens to the timeline and opens after the hover delay', () => {
    new ProjectTimelineTooltipPopover(timeline as unknown as Timeline, container, builder);
    expect(timeline.registered).toBe(3);

    hoverItem();
    vi.advanceTimersByTime(500);
    expect(popover()?.matches(':popover-open')).toBe(true);
  });

  it('anchors on the visible part of a clipped item', () => {
    container.style.cssText = 'position: relative; width: 100px; height: 40px; overflow: hidden;';
    item.style.cssText = 'position: absolute; left: 50px; top: 10px; width: 100px; height: 20px;';
    new ProjectTimelineTooltipPopover(timeline as unknown as Timeline, container, builder);

    hoverItem();
    vi.advanceTimersByTime(500);

    const anchor = (popover() as unknown as { anchorElement:DOMRect }).anchorElement;
    const clipRight = container.getBoundingClientRect().left + container.clientLeft + container.clientWidth;
    expect(anchor.right).toBeCloseTo(clipRight, 0);
    expect(anchor.width).toBeCloseTo(50, 0);
  });

  it('unregisters its timeline handlers and removes its host on destroy', () => {
    const tooltip = new ProjectTimelineTooltipPopover(timeline as unknown as Timeline, container, builder);
    hoverItem();
    vi.advanceTimersByTime(500);

    tooltip.destroy();

    expect(timeline.registered).toBe(0);
    expect(popover()).toBeNull();
  });

  it('survives a hide after its host left the document', () => {
    const tooltip = new ProjectTimelineTooltipPopover(timeline as unknown as Timeline, container, builder);
    hoverItem();
    vi.advanceTimersByTime(500);

    container.remove();
    expect(() => tooltip.hide()).not.toThrow();
    expect(() => tooltip.destroy()).not.toThrow();
  });
});

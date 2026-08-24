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

import {
  ChangeDetectionStrategy,
  Component,
  DestroyRef,
  ElementRef,
  ViewChild,
  ViewEncapsulation,
  afterNextRender,
  computed,
  effect,
  inject,
  input,
  signal,
} from '@angular/core';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { OpenprojectContentLoaderModule } from 'core-app/shared/components/op-content-loader/openproject-content-loader.module';
import { DataSet } from 'vis-data';
import { Timeline } from 'vis-timeline/standalone';
import type { DataItem } from 'vis-timeline/standalone';
import type AnchoredPositionElement from '@openproject/primer-view-components/app/components/primer/anchored_position';
import { html, nothing, render } from 'lit-html';
import { classMap } from 'lit-html/directives/class-map.js';
import { styleMap } from 'lit-html/directives/style-map.js';
import {
  GROUP_GATES,
  ProjectTimelineItemBuilder,
} from './project-timeline-item.builder';
import type { AccessibleProjectTimelineItem, ProjectPhaseData, ProjectMilestoneData, ProjectSprintData, ProjectTimelineItem } from './project-timeline-item.builder';
import { ProjectTimelineTooltipBuilder } from './project-timeline-tooltip.builder';
import { caretPlacement } from './project-timeline-tooltip-caret';
import type { CaretPlacement } from './project-timeline-tooltip-caret';

export type { ProjectTimelineItem } from './project-timeline-item.builder';

const TOOLTIP_DELAY_IN_MS = 500;

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

interface TooltipState {
  anchor:HTMLElement;
  content:HTMLElement | string;
  caret:CaretPlacement | null;
}

@Component({
  selector: 'opce-project-timeline-graph',
  templateUrl: './project-timeline-graph.component.html',
  styleUrls: ['./project-timeline-graph.component.sass'],
  changeDetection: ChangeDetectionStrategy.OnPush,
  encapsulation: ViewEncapsulation.None,
  imports: [OpenprojectContentLoaderModule],
  providers: [ProjectTimelineItemBuilder, ProjectTimelineTooltipBuilder],
})
export class ProjectTimelineGraphComponent {
  @ViewChild('container') containerRef!:ElementRef<HTMLDivElement>;

  readonly phasesData = input.required<string>();
  readonly milestonesData = input.required<string>();
  readonly sprintsData = input<string>('[]');

  readonly phases = computed<ProjectPhaseData[]>(
    () => JSON.parse(this.phasesData()) as ProjectPhaseData[],
  );

  readonly milestones = computed<ProjectMilestoneData[]>(
    () => JSON.parse(this.milestonesData()) as ProjectMilestoneData[],
  );

  readonly sprints = computed<ProjectSprintData[]>(
    () => JSON.parse(this.sprintsData()) as ProjectSprintData[],
  );

  readonly accessibleItems = computed<AccessibleProjectTimelineItem[]>(
    () => this.itemBuilder.buildAccessibleItems(this.phases()),
  );

  private readonly pathHelper = inject(PathHelperService);
  private readonly itemBuilder = inject(ProjectTimelineItemBuilder);
  private readonly tooltip = inject(ProjectTimelineTooltipBuilder);

  private timeline:Timeline | null = null;
  private itemsDataset:DataSet<ProjectTimelineItem> | null = null;
  private tooltipHost:HTMLElement | null = null;
  private tooltipState:TooltipState | null = null;
  private tooltipTimer:number | null = null;
  private tooltipObserver:MutationObserver | null = null;

  protected readonly ready = signal(false);

  constructor() {
    afterNextRender(() => this.initTimeline(this.phases(), this.milestones(), this.sprints()));
    inject(DestroyRef).onDestroy(() => {
      this.clearTooltipTimer();
      this.tooltipObserver?.disconnect();
      this.timeline?.destroy();
      this.timeline = null;
    });

    effect(() => {
      const phases = this.phases();
      const milestones = this.milestones();
      const sprints = this.sprints();
      if (this.timeline) {
        this.updateTimeline(phases, milestones, sprints);
      }
    });
  }

  private initTimeline(phases:ProjectPhaseData[], milestones:ProjectMilestoneData[], sprints:ProjectSprintData[]):void {
    const { items, groups } = this.itemBuilder.buildData(phases, milestones, sprints);
    this.itemsDataset = new DataSet(items);

    this.timeline = new Timeline(
      this.containerRef.nativeElement,
      this.itemsDataset as unknown as DataSet<DataItem>,
      new DataSet(groups),
      {
        editable: false,
        selectable: false,
        stack: false,
        orientation: { axis: 'top' },
        groupHeightMode: 'fixed',
        showMajorLabels: true,
        showMinorLabels: true,
        margin: { item: { horizontal: 0, vertical: 16 } },
        showCurrentTime: false, // enabled after the initial draw to avoid unnecessary redraws while loading
        zoomMin: 7 * 24 * 60 * 60 * 1000, // 7 days minimum zoom
        zoomMax: 50 * 365 * 24 * 60 * 60 * 1000, // 50 years maximum zoom
        onInitialDrawComplete: () => this.revealTimeline(),
        showTooltips: false,
        // eslint-disable-next-line @typescript-eslint/no-explicit-any,@typescript-eslint/no-unsafe-assignment
        tooltip: { template: this.tooltip.tooltipTemplate.bind(this.tooltip) } as any,
      },
    );

    this.initTooltip();
    this.timeline.on('itemover', (props:ItemHoverEvent) => this.showTooltip(props));
    this.timeline.on('itemout', () => this.hideTooltip());
    this.timeline.on('rangechange', () => this.hideTooltip());

    this.timeline.on('click', (props:{ item:string | null }) => {
      if (!props.item) return;
      const item = this.itemsDataset!.get(props.item);
      if (item?.itemType === 'milestone' && item.workPackageId) {
        window.location.href = this.pathHelper.workPackagePath(String(item.workPackageId));
      }
    });
  }

  // vis-timeline renders its own tooltip inside the timeline root, where the
  // dashboard grid cell (`.grid--area`, `overflow: hidden` + `z-index`) clips
  // it. A popover in the top layer escapes both. It stays a child of the
  // `aria-hidden` container so the sr-only list remains the only accessible
  // representation.
  // https://community.openproject.org/wp/SPPM-324
  private initTooltip():void {
    this.tooltipHost = document.createElement('div');
    this.containerRef.nativeElement.appendChild(this.tooltipHost);
    this.renderTooltip();

    // `anchored-position` repositions by writing `top`/`left` inline and does
    // not announce which side it settled on, so the caret is re-derived from
    // the resulting geometry after every such write.
    this.tooltipObserver = new MutationObserver(() => this.alignCaret());
    this.tooltipObserver.observe(this.tooltipPopover!, { attributes: true, attributeFilter: ['style'] });
  }

  private renderTooltip():void {
    if (!this.tooltipHost) return;

    const state = this.tooltipState;
    const caret = state?.caret;
    render(
      html`
        <anchored-position
          class="op-project-timeline-graph--tooltip"
          popover="manual"
          side="outside-top"
          align="center"
          anchor-offset="spacious"
          .anchorElement=${state?.anchor ?? null}>
          <div
            class=${classMap({
              'Popover-message': true,
              'Popover-message--bottom': caret?.side === 'bottom',
              'Popover-message--left': caret?.side === 'left',
              'Popover-message--right': caret?.side === 'right',
            })}
            style=${styleMap({ '--op-timeline-tooltip-caret-offset': caret ? `${caret.offset}px` : null })}>
            ${state?.content ?? nothing}
          </div>
        </anchored-position>
      `,
      this.tooltipHost,
    );
  }

  private get tooltipPopover():AnchoredPositionElement | null {
    return this.tooltipHost?.querySelector<AnchoredPositionElement>('anchored-position') ?? null;
  }

  private showTooltip({ item, event }:ItemHoverEvent):void {
    const anchor = event.target instanceof Element ? this.tooltipAnchor(event.target) : null;
    const content = this.visItemSet()?.getItemById(item)?.getTitle();
    if (!anchor || !content) {
      this.hideTooltip();
      return;
    }

    this.tooltipState = { anchor, content, caret: null };
    this.renderTooltip();

    this.clearTooltipTimer();
    this.tooltipTimer = window.setTimeout(() => {
      this.tooltipTimer = null;
      if (anchor.isConnected) this.tooltipPopover?.togglePopover(true);
    }, TOOLTIP_DELAY_IN_MS);
  }

  // Point items carry their marker in a nested `.vis-dot`; milestones draw the
  // diamond there while gates hide it and draw an icon in the content instead.
  private tooltipAnchor(target:Element):HTMLElement | null {
    const item = target.closest<HTMLElement>('.vis-item');
    const dot = item?.querySelector<HTMLElement>('.vis-dot');
    return (dot?.getClientRects().length ? dot : item) ?? null;
  }

  private alignCaret():void {
    const popover = this.tooltipPopover;
    const state = this.tooltipState;
    if (!popover || !state || !popover.matches(':popover-open')) return;

    const caret = caretPlacement(popover.getBoundingClientRect(), state.anchor.getBoundingClientRect());
    if (caret.side === state.caret?.side && caret.offset === state.caret.offset) return;

    this.tooltipState = { ...state, caret };
    this.renderTooltip();
  }

  private hideTooltip():void {
    this.clearTooltipTimer();
    this.tooltipPopover?.togglePopover(false);
    this.tooltipState = null;
    this.renderTooltip();
  }

  private clearTooltipTimer():void {
    if (this.tooltipTimer !== null) {
      window.clearTimeout(this.tooltipTimer);
      this.tooltipTimer = null;
    }
  }

  private visItemSet():VisItemSet | undefined {
    return (this.timeline as unknown as { itemSet?:VisItemSet } | null)?.itemSet;
  }

  private updateTimeline(phases:ProjectPhaseData[], milestones:ProjectMilestoneData[], sprints:ProjectSprintData[]):void {
    const { items, groups } = this.itemBuilder.buildData(phases, milestones, sprints);
    this.itemsDataset = new DataSet(items);
    this.hideTooltip();
    this.timeline!.setData({ items: this.itemsDataset as unknown as DataSet<DataItem>, groups: new DataSet(groups) });
  }

  private revealTimeline():void {
    if (!this.timeline) return;

    this.timeline.setOptions({
      showCurrentTime: true,
      cluster: { maxItems: 1, clusterCriteria: this.shouldCluster.bind(this) },
    });
    this.ready.set(true);
  }

  private shouldCluster(a:ProjectTimelineItem, b:ProjectTimelineItem):boolean {
    if (a.group !== GROUP_GATES || b.group !== GROUP_GATES) return false;

    const diff = Math.abs(new Date(a.start).getTime() - new Date(b.start).getTime());
    return diff <= 24 * 60 * 60 * 1000; // 24 hours
  }
}

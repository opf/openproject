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
import {
  GROUP_GATES,
  ProjectTimelineItemBuilder,
} from './project-timeline-item.builder';
import type { AccessibleProjectTimelineItem, ProjectPhaseData, ProjectMilestoneData, ProjectSprintData, ProjectTimelineItem } from './project-timeline-item.builder';
import { ProjectTimelineTooltipBuilder } from './project-timeline-tooltip.builder';

export type { ProjectTimelineItem } from './project-timeline-item.builder';

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
    () => this.itemBuilder.buildAccessibleItems(this.phases(), this.milestones(), this.sprints()),
  );

  private readonly pathHelper = inject(PathHelperService);
  private readonly itemBuilder = inject(ProjectTimelineItemBuilder);
  private readonly tooltip = inject(ProjectTimelineTooltipBuilder);

  private timeline:Timeline | null = null;
  private itemsDataset:DataSet<ProjectTimelineItem> | null = null;

  protected readonly ready = signal(false);

  constructor() {
    afterNextRender(() => this.initTimeline(this.phases(), this.milestones(), this.sprints()));
    inject(DestroyRef).onDestroy(() => {
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
        // eslint-disable-next-line @typescript-eslint/no-explicit-any,@typescript-eslint/no-unsafe-assignment
        tooltip: { template: this.tooltip.tooltipTemplate.bind(this.tooltip), overflowMethod: 'cap' } as any,
      },
    );

    this.timeline.on('click', (props:{ item:string | null }) => {
      if (!props.item) return;
      const item = this.itemsDataset!.get(props.item);
      if (item?.itemType === 'milestone' && item.workPackageId) {
        window.location.href = this.pathHelper.workPackagePath(String(item.workPackageId));
      }
    });
  }

  private updateTimeline(phases:ProjectPhaseData[], milestones:ProjectMilestoneData[], sprints:ProjectSprintData[]):void {
    const { items, groups } = this.itemBuilder.buildData(phases, milestones, sprints);
    this.itemsDataset = new DataSet(items);
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

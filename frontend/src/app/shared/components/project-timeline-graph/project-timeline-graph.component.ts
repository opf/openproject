// -- copyright
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

import {
  AfterViewInit,
  ChangeDetectionStrategy,
  Component,
  ElementRef,
  OnDestroy,
  ViewChild,
  ViewEncapsulation,
  computed,
  effect,
  inject,
  input,
} from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { TimezoneService } from 'core-app/core/datetime/timezone.service';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { DataSet } from 'vis-data';
import { Timeline } from 'vis-timeline/standalone';
import type { DataItem } from 'vis-timeline/standalone';
import { diamondIconData, opGateIconData, opPhaseIconData } from '@openproject/octicons-angular';
import { octiconElement } from 'core-app/shared/helpers/op-icon-builder';

interface ProjectPhaseData {
  id:number;
  definitionId:number;
  name:string;
  startDate:string|null;
  endDate:string|null;
  startGate:boolean;
  startGateName:string|null;
  finishGate:boolean;
  finishGateName:string|null;
}

interface ProjectMilestoneData {
  id:number;
  subject:string;
  date:string;
  typeId:number;
}

export interface ProjectTimelineItem {
  id:string;
  group:string;
  start:Date|string;
  end?:Date|string;
  originalEnd?:Date|string;
  content:string|HTMLElement;
  title:string;
  type:'range'|'point'|'background';
  className:string;
  itemType?:'phase'|'gate'|'milestone';
  subgroup?:string;
  definitionId?:number;
  typeId?:number;
  workPackageId?:number;
}

const GROUP_GATES = 'gates';
const GROUP_PHASES = 'phases';
const GROUP_MILESTONES = 'milestones';

@Component({
  selector: 'opce-project-timeline-graph',
  templateUrl: './project-timeline-graph.component.html',
  styleUrls: ['./project-timeline-graph.component.sass'],
  changeDetection: ChangeDetectionStrategy.OnPush,
  encapsulation: ViewEncapsulation.None,
})
export class ProjectTimelineGraphComponent implements AfterViewInit, OnDestroy {
  @ViewChild('container') containerRef!:ElementRef<HTMLDivElement>;

  readonly phasesData = input.required<string>();
  readonly milestonesData = input.required<string>();

  readonly phases = computed<ProjectPhaseData[]>(
    () => JSON.parse(this.phasesData()) as ProjectPhaseData[],
  );

  readonly milestones = computed<ProjectMilestoneData[]>(
    () => JSON.parse(this.milestonesData()) as ProjectMilestoneData[],
  );

  private readonly i18n = inject(I18nService);
  private readonly timezone = inject(TimezoneService);
  private readonly pathHelper = inject(PathHelperService);

  private timeline:Timeline | null = null;
  private itemsDataset:DataSet<ProjectTimelineItem> | null = null;

  constructor() {
    effect(() => {
      const phases = this.phases();
      const milestones = this.milestones();
      if (this.timeline) {
        this.updateTimeline(phases, milestones);
      }
    });
  }

  ngAfterViewInit():void {
    this.initTimeline(this.phases(), this.milestones());
  }

  ngOnDestroy():void {
    this.timeline?.destroy();
    this.timeline = null;
  }

  private buildData(phases:ProjectPhaseData[], milestones:ProjectMilestoneData[]) {
    const items:ProjectTimelineItem[] = [];

    for (const phase of phases) {
      if (phase.startDate && phase.endDate) {
        items.push(this.buildPhaseItem(phase));
      }
      if (phase.startGate && phase.startDate) {
        items.push(this.buildGateItem(phase, 'start'));
      }
      if (phase.finishGate && phase.endDate) {
        items.push(this.buildGateItem(phase, 'finish'));
      }
    }

    const milestoneSubgroupIndex:Record<string, number> = {};
    for (const milestone of milestones) {
      const subGroupIndex = milestoneSubgroupIndex[milestone.date] ?? 0;
      milestoneSubgroupIndex[milestone.date] = subGroupIndex + 1;
      items.push(this.buildMilestoneItem(milestone, subGroupIndex));
    }

    const groups = [
      { id: GROUP_GATES, content: '' },
      { id: GROUP_PHASES, content: '' },
      { id: GROUP_MILESTONES, content: '' },
    ];

    return { items, groups };
  }

  private initTimeline(phases:ProjectPhaseData[], milestones:ProjectMilestoneData[]):void {
    const { items, groups } = this.buildData(phases, milestones);
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
        zoomMin: 7 * 24 * 60 * 60 * 1000, // 7 days minimum zoom
        cluster: { maxItems: 1, clusterCriteria: this.shouldCluster.bind(this) },
        // eslint-disable-next-line @typescript-eslint/no-explicit-any,@typescript-eslint/no-unsafe-assignment
        tooltip: { template: this.tooltipTemplate.bind(this) } as any,
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

  private updateTimeline(phases:ProjectPhaseData[], milestones:ProjectMilestoneData[]):void {
    const { items, groups } = this.buildData(phases, milestones);
    this.itemsDataset = new DataSet(items);
    this.timeline!.setData({ items: this.itemsDataset as unknown as DataSet<DataItem>, groups: new DataSet(groups) });
  }

  private tooltipTemplate(item:ProjectTimelineItem):HTMLElement | string {
    if (item.type === 'background') return '';

    const name = document.createElement('div');
    name.className = 'op-timeline-tooltip--name';
    name.textContent = item.title;

    const wrapper = document.createElement('div');
    wrapper.className = 'op-timeline-tooltip';
    wrapper.append(this.buildTooltipMetaRow(item), name);
    return wrapper;
  }

  private shouldCluster(a:ProjectTimelineItem, b:ProjectTimelineItem):boolean {
    if (a.group !== GROUP_GATES || b.group !== GROUP_GATES) return false;

    const diff = Math.abs(new Date(a.start).getTime() - new Date(b.start).getTime());
    return diff <= 24 * 60 * 60 * 1000; // 24 hours
  }

  private buildTooltipMetaRow(item:ProjectTimelineItem):HTMLElement {
    const typeSpan = document.createElement('span');
    typeSpan.className = 'op-timeline-tooltip--type';
    typeSpan.append(this.tooltipTypeLabel(item.itemType));

    const metaRow = document.createElement('div');
    metaRow.className = 'op-timeline-tooltip--meta-row';
    metaRow.append(`${this.tooltipDateStr(item)} `, this.tooltipIcon(item), typeSpan);
    return metaRow;
  }

  private tooltipDateStr(item:ProjectTimelineItem):string {
    const fmt = (d:Date | string) => this.timezone.formattedDate(d as string);
    const isSingleDate = item.itemType === 'milestone' || item.itemType === 'gate';
    if (isSingleDate) return fmt(item.start);
    return item.originalEnd
      ? fmt(item.originalEnd)
      : `${fmt(item.start)} – ${fmt(item.end!)}`;
  }

  private tooltipTypeLabel(itemType:ProjectTimelineItem['itemType']):string {
    if (itemType === 'milestone') return this.i18n.t('js.grid.widgets.project_timeline.tooltip_type_milestone');
    if (itemType === 'gate') return this.i18n.t('js.grid.widgets.project_timeline.tooltip_type_gate');
    return this.i18n.t('js.grid.widgets.project_timeline.tooltip_type_phase');
  }

  private tooltipIcon(item:ProjectTimelineItem):HTMLElement {
    if (item.itemType === 'milestone') {
      return octiconElement(diamondIconData, 'xsmall', `octicon __hl_inline_type_${item.typeId!}`);
    }
    const iconData = item.itemType === 'gate' ? opGateIconData : opPhaseIconData;
    return octiconElement(iconData, 'small', `octicon __hl_inline_project_phase_definition_${item.definitionId!}`);
  }

  private buildPhaseItem(phase:ProjectPhaseData):ProjectTimelineItem {
    const hlClass = `__hl_background_project_phase_definition_${phase.definitionId}`;
    const isOneDay = phase.startDate === phase.endDate;
    let start:Date | string = phase.startDate!;
    let end:Date | string = phase.endDate!;
    if (isOneDay) {
      const startNoon = new Date(`${phase.startDate}T12:00:00`);
      startNoon.setDate(startNoon.getDate() - 1);
      start = startNoon;
      end = new Date(`${phase.endDate}T12:00:00`);
    }
    return {
      id: `phase-${phase.id}`,
      group: GROUP_PHASES,
      start,
      end,
      originalEnd: isOneDay ? phase.endDate! : undefined,
      content: phase.name,
      title: phase.name,
      type: 'range',
      className: hlClass,
      itemType: 'phase',
      definitionId: phase.definitionId,
    };
  }

  private buildGateItem(phase:ProjectPhaseData, position:'start'|'finish'):ProjectTimelineItem {
    const hlClass = `__hl_background_project_phase_definition_${phase.definitionId}`;
    const hlInlineClass = `__hl_inline_project_phase_definition_${phase.definitionId}`;
    const isFinish = position === 'finish';
    const icon = octiconElement(opGateIconData, 'small', `octicon ${hlInlineClass}`);
    return {
      id: `gate-${position}-${phase.id}`,
      group: GROUP_GATES,
      start: isFinish ? phase.endDate! : phase.startDate!,
      content: icon,
      title: (isFinish ? phase.finishGateName : phase.startGateName) ?? phase.name,
      type: 'point',
      className: `op-timeline-gate${isFinish ? ' op-timeline-gate--finish' : ''} ${hlClass}`,
      itemType: 'gate',
      definitionId: phase.definitionId,
    };
  }

  private buildMilestoneItem(milestone:ProjectMilestoneData, subgroupIndex:number):ProjectTimelineItem {
    const hlClass = `__hl_background_type_${milestone.typeId}`;
    return {
      id: `milestone-${milestone.id}`,
      group: GROUP_MILESTONES,
      subgroup: String(subgroupIndex),
      start: milestone.date,
      content: '',
      title: milestone.subject,
      type: 'point',
      className: `op-timeline-milestone ${hlClass}`,
      itemType: 'milestone',
      typeId: milestone.typeId,
      workPackageId: milestone.id,
    };
  }
}

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
import { DataSet } from 'vis-data';
import { Timeline } from 'vis-timeline/standalone';
import type { DataItem } from 'vis-timeline/standalone';
import { opGateIconData, opPhaseIconData } from '@openproject/octicons-angular';
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
export interface ProjectTimelineItem {
  id:string;
  group:string;
  start:Date|string;
  end?:Date|string;
  content:string|HTMLElement;
  title:string;
  type:'range'|'point'|'background';
  className:string;
  definitionId?:number;
}

const GROUP_GATES = 'gates';
const GROUP_LIFECYCLE = 'lifecycle';

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

  readonly phases = computed<ProjectPhaseData[]>(
    () => JSON.parse(this.phasesData()) as ProjectPhaseData[],
  );

  private readonly i18n = inject(I18nService);

  private timeline:Timeline | null = null;

  constructor() {
    effect(() => {
      const phases = this.phases();
      if (this.timeline) {
        this.updateTimeline(phases);
      }
    });
  }

  ngAfterViewInit():void {
    this.initTimeline(this.phases());
  }

  ngOnDestroy():void {
    this.timeline?.destroy();
    this.timeline = null;
  }

  private buildData(phases:ProjectPhaseData[]) {
    const items:ProjectTimelineItem[] = [];

    for (const phase of phases) {
      const hlClass = `__hl_background_project_phase_definition_${phase.definitionId}`;
      const hlInlineClass = `__hl_inline_project_phase_definition_${phase.definitionId}`;

      if (phase.startDate && phase.endDate) {
        items.push({
          id: `phase-${phase.id}`,
          group: GROUP_LIFECYCLE,
          start: phase.startDate,
          end: phase.endDate,
          content: phase.name,
          title: phase.name,
          type: 'range',
          className: hlClass,
          definitionId: phase.definitionId,
        });
      }

      if (phase.startGate && phase.startDate) {
        const icon = octiconElement(opGateIconData, 'small', `octicon ${hlInlineClass}`);
        items.push({
          id: `gate-start-${phase.id}`,
          group: GROUP_GATES,
          start: phase.startDate,
          content: icon,
          title: phase.startGateName ?? phase.name,
          type: 'point',
          className: `op-timeline-gate ${hlClass}`,
          definitionId: phase.definitionId,
        });
      }

      if (phase.finishGate && phase.endDate) {
        const icon = octiconElement(opGateIconData, 'small', `octicon ${hlInlineClass}`);
        items.push({
          id: `gate-finish-${phase.id}`,
          group: GROUP_GATES,
          start: phase.endDate,
          content: icon,
          title: phase.finishGateName ?? phase.name,
          type: 'point',
          className: `op-timeline-gate op-timeline-gate--finish ${hlClass}`,
          definitionId: phase.definitionId,
        });
      }
    }

    const groups = [
      { id: GROUP_GATES, content: '' },
      { id: GROUP_LIFECYCLE, content: '' },
    ];

    return { items, groups };
  }

  private initTimeline(phases:ProjectPhaseData[]):void {
    const { items, groups } = this.buildData(phases);

    this.timeline = new Timeline(
      this.containerRef.nativeElement,
      new DataSet(items as unknown as DataItem[]),
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
        // eslint-disable-next-line @typescript-eslint/no-explicit-any,@typescript-eslint/no-unsafe-assignment
        tooltip: { template: this.tooltipTemplate.bind(this) } as any,
      },
    );
  }

  private tooltipTemplate(item:ProjectTimelineItem):HTMLElement | string {
    if (item.type === 'background') return '';

    const isGate = item.type === 'point';
    const formatDate = (d:Date | string) => new Date(d).toLocaleDateString();
    const dateStr = isGate
      ? formatDate(item.start)
      : `${formatDate(item.start)} – ${formatDate(item.end!)}`;
    const typeLabel = isGate
      ? this.i18n.t('js.grid.widgets.project_timeline.tooltip_type_gate')
      : this.i18n.t('js.grid.widgets.project_timeline.tooltip_type_phase');

    const hlInlineClass = `__hl_inline_project_phase_definition_${item.definitionId!}`;

    const icon = octiconElement(isGate ? opGateIconData : opPhaseIconData, 'small', `octicon ${hlInlineClass}`);
    const typeSpan = document.createElement('span');
    typeSpan.className = 'op-timeline-tooltip--type';
    typeSpan.append(typeLabel);

    const metaRow = document.createElement('div');
    metaRow.className = 'op-timeline-tooltip--meta-row';
    metaRow.append(`${dateStr} `, icon, typeSpan);

    const name = document.createElement('div');
    name.className = 'op-timeline-tooltip--name';
    name.textContent = item.title;

    const wrapper = document.createElement('div');
    wrapper.className = 'op-timeline-tooltip';
    wrapper.append(metaRow, name);

    return wrapper;
  }

  private updateTimeline(phases:ProjectPhaseData[]):void {
    const { items, groups } = this.buildData(phases);
    this.timeline!.setData({ items: new DataSet(items as unknown as DataItem[]), groups: new DataSet(groups) });
  }
}

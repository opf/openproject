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

import { Injectable, inject } from '@angular/core';
import { opGateIconData } from '@openproject/octicons-angular';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { TimezoneService } from 'core-app/core/datetime/timezone.service';
import { octiconElement } from 'core-app/shared/helpers/op-icon-builder';

export interface ProjectPhaseData {
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

export interface ProjectMilestoneData {
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
  isCluster?:boolean;
  items?:ProjectTimelineItem[];
}

export interface AccessibleProjectTimelineItem {
  id:string;
  text:string;
}

export const GROUP_GATES = 'gates';
export const GROUP_PHASES = 'phases';
export const GROUP_MILESTONES = 'milestones';

@Injectable()
export class ProjectTimelineItemBuilder {
  private readonly i18n = inject(I18nService);
  private readonly timezone = inject(TimezoneService);

  buildData(phases:ProjectPhaseData[], milestones:ProjectMilestoneData[]):{items:ProjectTimelineItem[]; groups:{id:string; content:string}[]} {
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

  buildPhaseItem(phase:ProjectPhaseData):ProjectTimelineItem {
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

  buildGateItem(phase:ProjectPhaseData, position:'start'|'finish'):ProjectTimelineItem {
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

  buildMilestoneItem(milestone:ProjectMilestoneData, subgroupIndex:number):ProjectTimelineItem {
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

  buildAccessibleItems(phases:ProjectPhaseData[]):AccessibleProjectTimelineItem[] {
    const items:AccessibleProjectTimelineItem[] = [];

    for (const phase of phases) {
      if (phase.startDate && phase.endDate) {
        items.push({
          id: `phase-${phase.id}`,
          text: this.i18n.t('js.grid.widgets.project_timeline.accessible_phase', {
            name: phase.name,
            date: this.accessiblePhaseDate(phase),
          }),
        });
      }

      if (phase.startGate && phase.startDate) {
        items.push({
          id: `gate-start-${phase.id}`,
          text: this.accessibleGateText(phase.startGateName ?? phase.name, phase.startDate),
        });
      }

      if (phase.finishGate && phase.endDate) {
        items.push({
          id: `gate-finish-${phase.id}`,
          text: this.accessibleGateText(phase.finishGateName ?? phase.name, phase.endDate),
        });
      }
    }

    return items;
  }

  private accessiblePhaseDate(phase:ProjectPhaseData):string {
    const start = this.timezone.formattedDate(phase.startDate!);
    const end = this.timezone.formattedDate(phase.endDate!);

    if (phase.startDate === phase.endDate) {
      return start;
    }

    return this.i18n.t('js.grid.widgets.project_timeline.accessible_date_range', { start, end });
  }

  private accessibleGateText(name:string, date:string):string {
    return this.i18n.t('js.grid.widgets.project_timeline.accessible_gate', {
      name,
      date: this.timezone.formattedDate(date),
    });
  }
}

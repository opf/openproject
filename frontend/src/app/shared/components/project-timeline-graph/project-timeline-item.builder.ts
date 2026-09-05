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
  row:number;
}

export interface ProjectSprintData {
  id:number;
  name:string;
  startDate:string;
  endDate:string;
  status:string;
  row:number;
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
  itemType?:'phase'|'gate'|'milestone'|'sprint';
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
export const GROUP_SPRINTS = 'sprints';

@Injectable()
export class ProjectTimelineItemBuilder {
  private readonly i18n = inject(I18nService);
  private readonly timezone = inject(TimezoneService);

  buildData(phases:ProjectPhaseData[], milestones:ProjectMilestoneData[], sprints:ProjectSprintData[]):{items:ProjectTimelineItem[]; groups:{id:string; content:string}[]} {
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

    for (const milestone of milestones) {
      items.push(this.buildMilestoneItem(milestone));
    }

    for (const sprint of sprints) {
      items.push(this.buildSprintItem(sprint));
    }

    const groups = [
      { id: GROUP_GATES, content: '', className: 'op-timeline-group--gates' },
      { id: GROUP_PHASES, content: '' },
      { id: GROUP_MILESTONES, content: '' },
      { id: GROUP_SPRINTS, content: '' },
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

  buildMilestoneItem(milestone:ProjectMilestoneData):ProjectTimelineItem {
    const hlClass = `__hl_background_type_${milestone.typeId}`;
    return {
      id: `milestone-${milestone.id}`,
      group: GROUP_MILESTONES,
      subgroup: String(milestone.row),
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

  buildSprintItem(sprint:ProjectSprintData):ProjectTimelineItem {
    const isActive = sprint.status === 'active';
    return {
      id: `sprint-${sprint.id}`,
      group: GROUP_SPRINTS,
      subgroup: String(sprint.row),
      start: sprint.startDate,
      end: sprint.endDate,
      content: sprint.name,
      title: sprint.name,
      type: 'range',
      className: `op-timeline-sprint${isActive ? ' op-timeline-sprint--active' : ''}`,
      itemType: 'sprint',
    };
  }

  buildAccessibleItems(
    phases:ProjectPhaseData[],
    milestones:ProjectMilestoneData[],
    sprints:ProjectSprintData[],
  ):AccessibleProjectTimelineItem[] {
    const items:(AccessibleProjectTimelineItem & { date:string })[] = [];

    for (const phase of phases) {
      if (phase.startDate && phase.endDate) {
        items.push({
          id: `phase-${phase.id}`,
          date: phase.startDate,
          text: this.i18n.t('js.grid.widgets.project_timeline.accessible_phase', {
            name: phase.name,
            date: this.accessibleDate(phase.startDate, phase.endDate),
          }),
        });
      }

      if (phase.startGate && phase.startDate) {
        items.push({
          id: `gate-start-${phase.id}`,
          date: phase.startDate,
          text: this.accessibleGateText(phase.startGateName ?? phase.name, phase.startDate),
        });
      }

      if (phase.finishGate && phase.endDate) {
        items.push({
          id: `gate-finish-${phase.id}`,
          date: phase.endDate,
          text: this.accessibleGateText(phase.finishGateName ?? phase.name, phase.endDate),
        });
      }
    }

    for (const milestone of milestones) {
      items.push({
        id: `milestone-${milestone.id}`,
        date: milestone.date,
        text: this.i18n.t('js.grid.widgets.project_timeline.accessible_milestone', {
          name: milestone.subject,
          date: this.timezone.formattedDate(milestone.date),
        }),
      });
    }

    for (const sprint of sprints) {
      items.push({
        id: `sprint-${sprint.id}`,
        date: sprint.startDate,
        text: this.i18n.t('js.grid.widgets.project_timeline.accessible_sprint', {
          name: sprint.name,
          date: this.accessibleDate(sprint.startDate, sprint.endDate),
          status: this.i18n.t<string>(`js.grid.widgets.project_timeline.sprint_status.${sprint.status}`),
        }),
      });
    }

    return items
      .sort((a, b) => a.date.localeCompare(b.date))
      .map(({ id, text }) => ({ id, text }));
  }

  private accessibleDate(startDate:string, endDate:string):string {
    const start = this.timezone.formattedDate(startDate);
    const end = this.timezone.formattedDate(endDate);

    if (startDate === endDate) {
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

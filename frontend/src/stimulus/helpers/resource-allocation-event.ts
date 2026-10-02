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

import { html, nothing, TemplateResult } from 'lit-html';
import { unsafeHTML } from 'lit-html/directives/unsafe-html.js';
import { calendarIconData, opPersonAssignedIconData, toDOMString } from '@openproject/octicons-angular';
import type { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { displayDuration } from 'core-stimulus/helpers/duration-helpers';
import type { TimeEntryEvent } from 'core-stimulus/helpers/time-entry-event';

// What FullCalendar::ResourceAllocationEvent serializes. The work package and project
// attributes are left out for a work package the user cannot see.
export interface ResourceAllocationEvent {
  id:string;
  groupId:string;
  start:string;
  end:string;
  allDay:boolean;
  title:string;
  classNames:string[];
  allocationId:number;
  hours:number;
  dueDate:string;
  formattedDueDate:string;
  typeId?:number;
  workPackageId?:string;
  workPackageFormattedId?:string;
  workPackageSubject?:string;
  projectId?:number;
  projectIdentifier?:string;
  projectName?:string;
}

// A running timer has no final hours yet.
export function remainingHours(
  allocation:ResourceAllocationEvent,
  timeEntries:Pick<TimeEntryEvent, 'start'|'hours'|'ongoing'|'workPackageId'>[],
):number {
  const day = allocation.start.slice(0, 10);
  const logged = timeEntries
    .filter((entry) => !entry.ongoing
      && entry.workPackageId === allocation.workPackageId
      && entry.start.slice(0, 10) === day)
    .reduce((sum, entry) => sum + entry.hours, 0);

  return Math.max(Math.round((allocation.hours - logged) * 100) / 100, 0);
}

export function remainingAllocations(
  allocations:ResourceAllocationEvent[],
  timeEntries:Pick<TimeEntryEvent, 'start'|'hours'|'ongoing'|'workPackageId'>[],
):ResourceAllocationEvent[] {
  return allocations
    .map((allocation) => ({ ...allocation, hours: remainingHours(allocation, timeEntries) }))
    .filter((allocation) => allocation.hours > 0);
}

const icon = (data:Parameters<typeof toDOMString>[0]) => unsafeHTML(toDOMString(data, 'small', {
  'aria-hidden': 'true',
  class: 'octicon',
}));

export function renderAllocationCard(
  allocation:ResourceAllocationEvent,
  day:string,
  today:string,
  pathHelperService:PathHelperService,
):TemplateResult {
  return html`
    <div class="te-entry-card">
      <div class="te-entry-card--duration">${displayDuration(allocation.hours)}</div>
      ${renderWorkPackage(allocation, pathHelperService)}
      <div class="te-entry-card--due ${allocation.dueDate === day ? 'te-entry-card--due-attention' : ''}">
        ${icon(calendarIconData)}
        ${allocation.dueDate === today
          ? I18n.t('js.resource_management.my_work.due_today')
          : I18n.t('js.resource_management.my_work.due_on', { date: allocation.formattedDueDate })}
      </div>
      <div class="te-entry-card--icon">${icon(opPersonAssignedIconData)}</div>
    </div>`;
}

function renderWorkPackage(allocation:ResourceAllocationEvent, pathHelperService:PathHelperService):TemplateResult {
  if (!allocation.workPackageId) {
    return html`<div class="te-entry-card--subject">${allocation.title}</div>`;
  }

  return html`
    <div class="te-entry-card--subject" title="${allocation.workPackageSubject}">
      <a class="Link--primary Link"
         href="${pathHelperService.workPackageShortPath(allocation.workPackageId)}">${allocation.workPackageFormattedId}</a>:
      ${allocation.workPackageSubject}
    </div>
    ${allocation.projectIdentifier ? html`
      <div class="te-entry-card--project" title="${allocation.projectName}">
        <a class="Link--secondary Link"
           href="${pathHelperService.projectPath(allocation.projectIdentifier)}">${allocation.projectName}</a>
      </div>` : nothing}`;
}

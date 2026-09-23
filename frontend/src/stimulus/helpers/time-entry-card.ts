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
import { clockIconData, opStopwatchStopIconData, toDOMString } from '@openproject/octicons-angular';
import type { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { displayDuration } from 'core-stimulus/helpers/duration-helpers';

// The fields of FullCalendar::TimeEntryEvent the card renders. Both my time tracking
// views are served the same payload.
export interface TimeEntryCard {
  hours:number;
  timeRange?:string;
  ongoing:boolean;
  workPackageId:string;
  workPackageFormattedId:string;
  workPackageSubject:string;
  projectIdentifier:string;
  projectName:string;
}

// Goes on the element the card is rendered into, which each view names for itself.
export const ONGOING_CLASS_NAME = 'te-entry-card-ongoing';

export function renderTimeEntryCard(
  entry:TimeEntryCard,
  pathHelperService:PathHelperService,
):TemplateResult {
  const clock = toDOMString(clockIconData, 'small', {
    'aria-hidden': 'true',
    class: 'octicon',
  });

  const timer = toDOMString(opStopwatchStopIconData, 'small', {
    'aria-hidden': 'true',
    class: 'octicon te-entry-card--timer',
  });

  return html`
    <div class="te-entry-card">
      <div class="te-entry-card--duration">
        ${entry.ongoing ? unsafeHTML(timer) : nothing}
        ${displayDuration(entry.hours)}
        ${entry.timeRange ? html`<span class="te-entry-card--times">${entry.timeRange}</span>` : nothing}
      </div>
      <div class="te-entry-card--subject" title="${entry.workPackageSubject}">
        <a class="Link--primary Link"
           href="${pathHelperService.workPackageShortPath(entry.workPackageId)}">${entry.workPackageFormattedId}</a>:
        ${entry.workPackageSubject}
      </div>
      <div class="te-entry-card--project" title="${entry.projectName}">
        <a class="Link--secondary Link"
           href="${pathHelperService.projectPath(entry.projectIdentifier)}">${entry.projectName}</a>
      </div>
      <div class="te-entry-card--icon">${unsafeHTML(clock)}</div>
    </div>`;
}

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

import { HalSourceLink } from 'core-app/features/hal/interfaces';

export interface INotificationSetting {
  _links:{ project:HalSourceLink };
  watched:boolean;
  assignee:boolean;
  responsible:boolean;
  shared:boolean;
  mentioned:boolean;
  workPackageCommented:boolean;
  workPackageCreated:boolean;
  workPackageProcessed:boolean;
  workPackagePrioritized:boolean;
  workPackageScheduled:boolean;
  newsAdded:boolean;
  newsCommented:boolean;
  documentAdded:boolean;
  forumMessages:boolean;
  wikiPageAdded:boolean;
  wikiPageUpdated:boolean;
  membershipAdded:boolean;
  membershipUpdated:boolean;
  startDate?:string|null;
  dueDate?:string|null;
  overdue?:string|null;
}

export function buildNotificationSetting(project:null|HalSourceLink, params:Partial<INotificationSetting>):INotificationSetting {
  return {
    _links: {
      project: {
        href: project ? project.href : null,
        title: project?.title,
      },
    },
    assignee: true,
    responsible: true,
    shared: true,
    mentioned: true,
    watched: true,
    workPackageCommented: true,
    workPackageCreated: true,
    workPackageProcessed: true,
    workPackagePrioritized: true,
    workPackageScheduled: true,
    newsAdded: true,
    newsCommented: true,
    documentAdded: true,
    forumMessages: true,
    wikiPageAdded: true,
    wikiPageUpdated: true,
    membershipAdded: true,
    membershipUpdated: true,
    startDate: 'P1D',
    dueDate: 'P1D',
    overdue: null,
    ...params,
  };
}

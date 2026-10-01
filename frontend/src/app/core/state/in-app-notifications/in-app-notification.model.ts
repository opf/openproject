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

import { ID } from '@datorama/akita';
import {
  IHalResourceLink,
  IHalResourceLinks,
} from 'core-app/core/state/hal-resource';

export const NOTIFICATIONS_MAX_SIZE = 100;

export interface IInAppNotificationHalResourceLinks extends IHalResourceLinks {
  actor:IHalResourceLink;
  project:IHalResourceLink;
  resource:IHalResourceLink;
  activity:IHalResourceLink;
}

export type IInAppNotificationDetailsAttribute = 'startDate'|'dueDate'|'date'|'note';

export interface IInAppNotificationDetailsResource {
  property:IInAppNotificationDetailsAttribute;
  value:string|null;

  _links:{
    self:IHalResourceLink;
    schema:IHalResourceLink;
  };
}

export interface IInAppNotificationHalResourceEmbedded {
  details:IInAppNotificationDetailsResource[];
}

export interface INotification {
  id:ID;
  subject:string;
  createdAt:string;
  updatedAt:string;
  reason:string;
  readIAN:boolean|null;
  readEmail:boolean|null;

  // Mark a notification to be kept in the center even though it was saved as "read".
  keep?:boolean;
  // Show message of a notification?
  expanded:boolean;

  _links:IInAppNotificationHalResourceLinks;
  _embedded:IInAppNotificationHalResourceEmbedded;
}

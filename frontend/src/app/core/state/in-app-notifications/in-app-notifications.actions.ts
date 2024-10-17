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
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { ID } from '@datorama/akita';
import {
  action,
  props,
} from 'ts-action';

import { ApiV3ListFilter } from 'core-app/core/apiv3/paths/apiv3-list-resource.interface';

export const markNotificationsAsRead = action(
  '[IAN] Mark notifications as read',
  props<{ origin:string, notifications:ID[] }>(),
);

export const markNotificationsAsReadByFilters = action(
  '[IAN] Mark notifications as read by filter',
  props<{ origin:string, filters:ApiV3ListFilter[] }>(),
);

export const notificationsMarkedRead = action(
  '[IAN] Notifications were marked as read',
  props<{ origin:string, notifications:ID[], all:boolean }>(),
);

export const notificationCountIncreased = action(
  '[IAN] The backend sent a notification count that was higher than the last known',
  props<{ origin:string, count:number }>(),
);

export const notificationCountChanged = action(
  '[IAN] The backend sent a notification count that was different to the last known',
  props<{ origin:string, count:number }>(),
);

export const centerUpdatedInPlace = action(
  '[IAN] The notification center updated the notification list without a full page refresh',
  props<{ origin:string }>(),
);

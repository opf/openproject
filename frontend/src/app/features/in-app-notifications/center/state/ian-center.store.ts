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

import { Store, StoreConfig } from '@datorama/akita';
import { CollectionResponse } from 'core-app/core/state/resource-store';
import { ApiV3ListFilter } from 'core-app/core/apiv3/paths/apiv3-list-resource.interface';
import { NOTIFICATIONS_MAX_SIZE } from 'core-app/core/state/in-app-notifications/in-app-notification.model';
import {
  INotificationPageQueryParameters,
} from 'core-app/features/in-app-notifications/center/state/ian-center.service';

export type InAppNotificationFacet = 'unread'|'all';

export interface IanCenterState {
  params:{
    page:number;
    pageSize:number;
  };
  activeFacet:InAppNotificationFacet;
  filters:INotificationPageQueryParameters;

  activeCollection:CollectionResponse;

  /** Number of elements not showing after max values loaded */
  notLoaded:number;
}

export const IAN_FACET_FILTERS:Record<InAppNotificationFacet, ApiV3ListFilter[]> = {
  unread: [['readIAN', '=', false]],
  all: [],
};

export function createInitialState():IanCenterState {
  return {
    params: {
      pageSize: NOTIFICATIONS_MAX_SIZE,
      page: 1,
    },
    filters: {},
    activeCollection: { ids: [] },
    activeFacet: 'unread',
    notLoaded: 0,
  };
}

@StoreConfig({ name: 'ian-center' })
export class IanCenterStore extends Store<IanCenterState> {
  constructor() {
    super(createInitialState());
  }
}

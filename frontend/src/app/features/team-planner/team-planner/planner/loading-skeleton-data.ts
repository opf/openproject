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

import moment from 'moment-timezone';

export const skeletonResources = [
  {
    id: 'skeleton-resource-1',
    title: '',
    href: 'skeleton-resource-1',
  },
  {
    id: 'skeleton-resource-2',
    title: '',
    href: 'skeleton-resource-2',
  },
  {
    id: 'skeleton-resource-3',
    title: '',
    href: 'skeleton-resource-3',
  },
];

const baseSkeleton = {
  editable: false,
  eventStartEditable: false,
  eventDurationEditable: false,
  allDay: true,
  backgroundColor: '#FFFFFF',
  borderColor: '#FFFFFF',
  title: '',
};

export const skeletonEvents = [
  {
    ...baseSkeleton,
    id: 'skeleton-1',
    resourceId: skeletonResources[0].id,
    start: moment().subtract(1, 'days').toDate(),
    end: moment().add(1, 'day').toDate(),
    viewBox: '0 0 800 80',
  },
  {
    ...baseSkeleton,
    id: 'skeleton-2',
    resourceId: skeletonResources[1].id,
    start: moment().subtract(3, 'days').toDate(),
    end: moment().toDate(),
    viewBox: '0 0 1200 80',
  },
  {
    ...baseSkeleton,
    id: 'skeleton-3',
    resourceId: skeletonResources[2].id,
    start: moment().toDate(),
    end: moment().add(3, 'days').toDate(),
    viewBox: '0 0 1200 80',
  },
];

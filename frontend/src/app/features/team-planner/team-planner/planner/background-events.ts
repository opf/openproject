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

import { Calendar } from '@fullcalendar/core';
import moment from 'moment/moment';

export const backgroundEvents = {
  events: [],
  id: 'background',
  color: 'red',
  textColor: 'white',
  display: 'background',
  editable: false,
};

export function addBackgroundEvents(
  calendar:Calendar,
  nonWorkingDay:(date:Date) => boolean,
) {
  let currentStartDate = calendar.view.activeStart;
  const currentEndDate = calendar.view.activeEnd.getTime();
  const nonWorkingDays = new Array<{ start:Date|string, end:Date|string }>();

  while (currentStartDate.getTime() < currentEndDate) {
    if (nonWorkingDay(currentStartDate)) {
      nonWorkingDays.push({
        start: moment(currentStartDate).format('YYYY-MM-DD'),
        end: moment(currentStartDate).add('1', 'day').format('YYYY-MM-DD'),
      });
    }
    currentStartDate = moment(currentStartDate).add('1', 'day').toDate();
  }
  nonWorkingDays.forEach((day) => {
    calendar.addEvent({ ...day }, 'background');
  });
}

export function removeBackgroundEvents(calendar:Calendar) {
  calendar
    .getEvents()
    .filter((el) => el.source?.id === 'background')
    .forEach((el) => el.remove());
}

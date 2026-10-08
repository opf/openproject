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
// along with this program. If not, see <https://www.gnu.org/licenses/>.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { DateTime } from 'luxon';

const LOCAL_DATETIME_FORMAT = "yyyy-LL-dd'T'HH:mm";

export function localDatetimeToISO(localValue:string, timeZone:string):string|null {
  if (!localValue) {
    return null;
  }

  return DateTime.fromISO(localValue, { zone: timeZone }).toISO({ suppressMilliseconds: true });
}

export function isoToLocalDatetime(isoValue:string|null|undefined, timeZone:string):string {
  if (!isoValue) {
    return '';
  }

  const time = DateTime.fromISO(isoValue, { zone: timeZone });

  return time.isValid ? time.toFormat(LOCAL_DATETIME_FORMAT) : '';
}

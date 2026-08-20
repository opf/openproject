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

import {
  parseChronicDuration,
  outputChronicDuration,
} from 'core-app/shared/helpers/chronic_duration';

export interface DurationLengthOptions {
  hoursPerDay?:number;
  daysPerMonth?:number;
}

// Mirrors the defaults of the Setting.hours_per_day / Setting.days_per_month settings,
// which are rendered as Stimulus values wherever a duration field is used.
export const HOURS_PER_DAY_DEFAULT = 8;
export const DAYS_PER_MONTH_DEFAULT = 20;

export function durationStringToSeconds(value:string, lengthOptions:DurationLengthOptions = {}):number {
  // Make sure we also accept german decimal commas
  const normalizedValue = value.replace(',', '.');

  return parseChronicDuration(normalizedValue, {
    defaultUnit: 'hours',
    ignoreSecondsWhenColonSeparated: true,
    ...lengthOptions,
  }) ?? 0;
}

export function formattedHour(seconds:number, blankOnNull = true):string {
  if (blankOnNull && (isNaN(seconds) || seconds <= 0)) {
    return '';
  }

  return outputChronicDuration(seconds, { format: 'hours_only' }) ?? '';
}

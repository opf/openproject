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

import { IWorkPackageTimestamp } from 'core-app/features/hal/resources/work-package-timestamp-resource';
import { ISchemaProxy } from 'core-app/features/hal/schemas/schema-proxy';
import { DEFAULT_TIMESTAMP } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-baseline.service';
import moment from 'moment-timezone';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { SchemaCacheService } from 'core-app/core/schemas/schema-cache.service';

export type BaselineOption = 'oneDayAgo'|'lastWorkingDay'|'oneWeekAgo'|'oneMonthAgo'|'aSpecificDate'|'betweenTwoSpecificDates';
export type BaselineMode = 'added'|'updated'|'removed'|null;

export interface BaselineTimestamp {
  date:string;
  time:string;
  offset:string;
}

const BASELINE_OPTIONS = ['oneDayAgo', 'lastWorkingDay', 'oneWeekAgo', 'oneMonthAgo', 'aSpecificDate', 'betweenTwoSpecificDates'];

export function baselineFilterFromValue(selectedDates:string[]):BaselineOption|null {
  if (selectedDates.length < 2) {
    return null;
  }

  const first = selectedDates[0].split('@')[0];
  if (BASELINE_OPTIONS.includes(first)) {
    return first as BaselineOption;
  }

  if (selectedDates[1] === DEFAULT_TIMESTAMP) {
    return 'aSpecificDate';
  }

  return 'betweenTwoSpecificDates';
}

export function getPartsFromTimestamp(value:string):BaselineTimestamp|null {
  if (value.includes('@')) {
    const [date, timeWithZone] = value.split(/[@]/);
    const [time, offset] = timeWithZone.split(/(?=[+-])/);
    return { date, time, offset };
  }

  if (value !== 'PT0S') {
    const dateObj = moment.parseZone(value);
    const date = dateObj.format('YYYY-MM-DD');
    const time = dateObj.format('HH:mm');
    const offset = dateObj.format('Z');

    return { date, time, offset };
  }

  return null;
}

export function attributeChanged(base:IWorkPackageTimestamp, schema:ISchemaProxy):boolean {
  return !!schema
    .availableAttributes
    .find((attribute) => {
      const name = schema.mappedName(attribute);
      return Object.prototype.hasOwnProperty.call(base, name) || Object.prototype.hasOwnProperty.call(base.$links, name);
    });
}

export function getBaselineState(workPackage:WorkPackageResource, schemaService:SchemaCacheService):BaselineMode {
  let state:BaselineMode = null;
  const schema = schemaService.of(workPackage);
  const timestamps = workPackage.attributesByTimestamp || [];
  if (timestamps.length > 1) {
    const base = timestamps[0];
    const compare = timestamps[1];
    if ((!base._meta.exists && compare._meta.exists) || (!base._meta.matchesFilters && compare._meta.matchesFilters)) {
      state = 'added';
    } else if ((base._meta.exists && !compare._meta.exists) || (base._meta.matchesFilters && !compare._meta.matchesFilters)) {
      state = 'removed';
    } else if (attributeChanged(base, schema)) {
      state = 'updated';
    }
  }
  return state;
}

export function offsetToUtcString(offset:string) {
  const mappedOffset = offset
    .replace(/^([+-])0/, '$1')
    .replace(':00', '')
    .replace(':30', '.5');

  return `UTC${mappedOffset}`;
}

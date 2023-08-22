import { IWorkPackageTimestamp } from 'core-app/features/hal/resources/work-package-timestamp-resource';
import { ISchemaProxy } from 'core-app/features/hal/schemas/schema-proxy';
import { DEFAULT_TIMESTAMP } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-baseline.service';
import * as moment from 'moment-timezone';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { SchemaCacheService } from 'core-app/core/schemas/schema-cache.service';

export type BaselineOption = 'oneDayAgo'|'lastWorkingDay'|'oneWeekAgo'|'oneMonthAgo'|'aSpecificDate'|'betweenTwoSpecificDates';

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

export function getBaselineState(workPackage:WorkPackageResource, schemaService:SchemaCacheService):string {
  let state = '';
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
  } else {
    state = '';
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

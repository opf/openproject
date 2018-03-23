import {GroupObject} from 'core-app/modules/hal/resources/wp-collection-resource';

export function groupIdentifier(group:GroupObject) {
  let value = group.value || 'nullValue';

  if (group.href) {
    try {
      value += group.href.map(el => el.href).join('-');
    } catch (e) {
      console.error('Failed to extract group identifier for ' + group.value);
    }
  }

  value = value.toLowerCase().replace(/[^a-z0-9]+/g, '-');
  return `${groupByProperty(group)}-${value}`;
}

export function groupName(group:GroupObject) {
  let value = group.value;
  if (value === null) {
    return '-';
  } else {
    return value;
  }
}

export function groupByProperty(group:GroupObject):string {
  return group._links.groupBy.href.split('/').pop()!;
}

/**
 * Get the row group class name for the given group id.
 */
export function groupedRowClassName(groupIndex:number) {
  return `__row-group-${groupIndex}`;
}

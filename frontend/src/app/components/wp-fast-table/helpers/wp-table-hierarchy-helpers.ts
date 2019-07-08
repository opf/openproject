import {WorkPackageResource} from 'core-app/modules/hal/resources/work-package-resource';
import {WorkPackageTable} from '../wp-fast-table';
/**
 * Returns the collapsed group class for the given ancestor id
 */
export function collapsedGroupClass(ancestorId:string):string {
  return `__collapsed-group-${ancestorId}`;
}

export function hierarchyGroupClass(ancestorId:string):string {
  return `__hierarchy-group-${ancestorId}`;
}

export function hierarchyRootClass(ancestorId:string):string {
  return `__hierarchy-root-${ancestorId}`;
}

export function ancestorClassIdentifier(ancestorId:string) {
  return `wp-ancestor-row-${ancestorId}`;
}

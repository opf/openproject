/**
 * Interface of a single row instance handled by the table.
 * May contain references to the current inserted row (if present)
 * or the group it belonged to when initially rendered.
 */
import { WorkPackageResource } from 'core-app/modules/hal/resources/work-package-resource';
import { GroupObject } from 'core-app/modules/hal/resources/wp-collection-resource';

export interface WorkPackageTableRow {
  object:WorkPackageResource;
  workPackageId:string;
  position:number;
  element?:HTMLElement;
  group:GroupObject|null;
}


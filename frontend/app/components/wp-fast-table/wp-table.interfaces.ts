import {
  WorkPackageResource,
  WorkPackageResourceInterface
} from '../api/api-v3/hal-resources/work-package-resource.service';
import {WorkPackageTable} from './wp-fast-table';

/**
 * Interface of a single row instance handled by the table.
 * May contain references to the current inserted row (if present)
 * or the group it belonged to when initially rendered.
 */
export interface WorkPackageTableRow {
  object:WorkPackageResourceInterface;
  workPackageId:string;
  position:number;
  element?:HTMLElement;
  group:GroupObject|null;
}

export interface GroupableColumn {
  name:string;
  title:string;
  sortable:boolean;
  groupable:boolean;
  custom_field:boolean;
}

/**
 * A reference to a group object as returned from the API.
 * Augmented with state information such as collapsed state.
 */
export interface GroupObject {
  value:any;
  count:number;
  collapsed?:boolean;
  index:number;
  identifier:string;
  href:{ href:string }[];
  _links?: {
    valueLink: { href:string }[];
  }
}

export interface WPTableRowSelectionState {
  // Map of selected rows
  selected: {[workPackageId: string]: boolean};
  // Index of current selection
  // required for shift-offsets
  activeRowIndex: number | null;
}

export interface WPTableHierarchyCollapsedState {
  [workPackageId: string]: boolean;
}

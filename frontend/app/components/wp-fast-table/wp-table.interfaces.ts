import {WorkPackageResource} from '../api/api-v3/hal-resources/work-package-resource.service';
export interface WorkPackageTableRow {
  object:WorkPackageResource;
  workPackageId:string;
  position:number;
  element?:HTMLElement;
}

export interface WorkPackageTableRowsState {
  [workPackageId:string]:WorkPackageTableRow;
}

export interface WorkPackageTableColumns {
  selected: string[];
  available: string[];
}

export interface WorkPackageTableGroupState {
  [group: string]: boolean;
}

export interface WPTableRowSelectionState {
  // Map of selected rows
  selected: {[workPackageId: number]: boolean};
  // Index of current selection
  // required for shift-offsets
  activeRowIndex: number | null;
}


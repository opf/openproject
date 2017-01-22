import {WorkPackageResource} from '../api/api-v3/hal-resources/work-package-resource.service';
export interface WorkPackageTableRow {
  workPackageId:number;
  position:number;
}

export interface WorkPackageTableRowsState {
  [workPackageId:number]:WorkPackageTableRow;
}

export interface WorkPackageTableColumns {
  selected: string[];
  available: string[];
}

export interface WorkPackageTableGroupState {
  [group: string]: boolean;
}

export interface WPTableRowSelectionState {
  // Set if all rows selected
  all: boolean;
  // Map of selected rows otherwise
  selected: {[workPackageId: number]: boolean};
  // Index of current selection
  // required for shift-offsets
  activeRowIndex: number | null;
}


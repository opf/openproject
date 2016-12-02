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

export interface WorkPackageTableRowSelectionState {
  [workPackageId: string]: boolean;
}


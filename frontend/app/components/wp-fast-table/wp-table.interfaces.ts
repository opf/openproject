import {WorkPackageResource} from '../api/api-v3/hal-resources/work-package-resource.service';
import {WorkPackageTable} from './wp-fast-table';
export interface WorkPackageTableRow {
  object:WorkPackageResource;
  workPackageId:string;
  position:number;
  element?:HTMLElement;
}

export interface WPTableRowSelectionState {
  // Map of selected rows
  selected: {[workPackageId: number]: boolean};
  // Index of current selection
  // required for shift-offsets
  activeRowIndex: number | null;
}

export interface RowsBuilderInterface {
  buildRows(table:WorkPackageTable):DocumentFragment;
  redrawRow(row:WorkPackageTableRow, table:WorkPackageTable):HTMLElement;
}

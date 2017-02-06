import {WorkPackageTable} from './wp-fast-table/wp-fast-table';
import {WPTableRowSelectionState, WorkPackageTableRow} from './wp-fast-table/wp-table.interfaces';
import {MultiState, initStates, State} from "../helpers/reactive-fassade";
import {WorkPackageResource} from "./api/api-v3/hal-resources/work-package-resource.service";
import {opServicesModule} from "../angular-modules";
import {SchemaResource} from './api/api-v3/hal-resources/schema-resource.service';
import {WorkPackageEditForm} from './wp-edit-form/work-package-edit-form';
import {WorkPackageTableMetadata} from './wp-fast-table/wp-table-metadata';


export class States {

  workPackages = new MultiState<WorkPackageResource>();
  schemas = new MultiState<SchemaResource>();

  // Work package table states
  table = {
    // Metadata of the current table result
    // (page, links, grouping information)
    metadata: new State<WorkPackageTableMetadata>(),
    // Set of work package IDs in strict order of appearance
    rows: new State<WorkPackageResource[]>(),
    // Set of columns in strict order of appearance
    columns: new State<string[]>(),
    // Table row selection state
    selection: new State<WPTableRowSelectionState>(),
    // Current state of collapsed groups (if any)
    collapsedGroups: new State<{[identifier:string]: boolean}>(),
    // State to be updated when the table is up to date
    rendered:new State<WorkPackageTable>()
  };

  // Query states
  query = {
    // All available columns for selection
    availableColumns: new State<any[]>()
  };

  // Current focused work package (e.g, row preselected for details button)
  focusedWorkPackage = new State<string>();

  // Open editing forms
  editing = new MultiState<WorkPackageEditForm>();

  constructor() {
    initStates(this, function (msg: any) {
      if (~location.hostname.indexOf("localhost")) {
        (console.trace as any)(msg); // RR: stupid hack to avoid compiler error
      }
    });
  }

}

opServicesModule.service('states', States);









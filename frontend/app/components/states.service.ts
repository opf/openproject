import {WPTableRowSelectionState, WorkPackageTableRow} from './wp-fast-table/wp-table.interfaces';
import {MultiState, initStates, State} from "../helpers/reactive-fassade";
import {WorkPackageResource} from "./api/api-v3/hal-resources/work-package-resource.service";
import {opServicesModule} from "../angular-modules";
import {SchemaResource} from './api/api-v3/hal-resources/schema-resource.service';
import {WorkPackageEditForm} from './wp-edit-form/work-package-edit-form';


export class States {

  workPackages = new MultiState<WorkPackageResource>();
  schemas = new MultiState<SchemaResource>();

  // Work package table states
  table = {
    // Set of rows in strict order of appearance
    rows: new State<Object[]>(),
    // Set of columns in strict order of appearance
    columns: new State<string[]>(),
    // Active row (highlight, preselected for details button)
    activeRow: new State<WorkPackageTableRow>(),
    // Table row selection state
    selection: new State<WPTableRowSelectionState>(),
    // Active editing rows
    group: new State<string[]>(),
  };

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









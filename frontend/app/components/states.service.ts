import {WPTableRowSelectionState, WorkPackageTableRow} from './wp-fast-table/wp-table.interfaces';
import {MultiState, initStates, State} from "../helpers/reactive-fassade";
import {WorkPackageResource} from "./api/api-v3/hal-resources/work-package-resource.service";
import {opServicesModule} from "../angular-modules";
import {SchemaResource} from './api/api-v3/hal-resources/schema-resource.service';


export class States {

  workPackages = new MultiState<WorkPackageResource>();
  schemas = new MultiState<SchemaResource>();

  // Work package table states
  table = {
    rows: new State<Object[]>(),
    columns: new State<string[]>(),
    activeRow: new State<WorkPackageTableRow>(),
    selection: new State<WPTableRowSelectionState>(),
    group: new State<string[]>()
  };

  tableRow = {
    // editing = new MultiState<WorkPackageEditForm>();
  };

  constructor() {
    initStates(this, function (msg: any) {
      if (~location.hostname.indexOf("localhost")) {
        (console.trace as any)(msg); // RR: stupid hack to avoid compiler error
      }
    });
  }

}

opServicesModule.service('states', States);









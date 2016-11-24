import {MultiState, initStates} from "../helpers/reactive-fassade";
import {WorkPackageResource} from "./api/api-v3/hal-resources/work-package-resource.service";
import {opServicesModule} from "../angular-modules";
import {SchemaResource} from './api/api-v3/hal-resources/schema-resource.service';

export class States {

  workPackages = new MultiState<WorkPackageResource>();
  schemas = new MultiState<SchemaResource>();

  constructor() {
    initStates(this, function (msg: any) {
      if (~location.hostname.indexOf("localhost")) {
        (console.trace as any)(msg); // RR: stupid hack to avoid compiler error
      }
    });
  }

}

opServicesModule.service('states', States);










import {MultiState, initStates} from "../helpers/reactive-fassade";
import {WorkPackageResource} from "./api/api-v3/hal-resources/work-package-resource.service";
import {opServicesModule} from "../angular-modules";
import {SchemaResource} from './api/api-v3/hal-resources/schema-resource.service';
import {TypeResource} from './api/api-v3/hal-resources/type-resource.service';

export class States {

  /* /api/v3/work_packages */
  workPackages = new MultiState<WorkPackageResource>();

  /* /api/v3/schemas */
  schemas = new MultiState<SchemaResource>();

  /* /api/v3/types */
  types = new MultiState<TypeResource>();

  constructor() {
    initStates(this, function (msg: any) {
      if (~location.hostname.indexOf("localhost")) {
        (console.debug as any)(msg); // RR: stupid hack to avoid compiler error
      }
    });
  }

}

opServicesModule.service('states', States);










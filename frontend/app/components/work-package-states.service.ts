import { MultiState, initStates } from '../helpers/reactive-fassade';
import {RelationResource} from './api/api-v3/hal-resources/relation-resource.service';
import {whenDebugging} from '../helpers/debug_output';
import { opServicesModule } from '../angular-modules';
import { RelationsStateValue } from "./wp-relations/wp-relations.service";



/* /api/v3/work_packages */
export class WorkPackageStates {

  /* /:id/relations */
  relations = new MultiState<RelationsStateValue>();

  constructor() {
    initStates(this, function (msg: any) {
      whenDebugging(() => {
        console.debug(msg);
      });
    });
  }

}

opServicesModule.service('wpStates', WorkPackageStates);

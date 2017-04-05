import {Component, createNewContext, inputStateCache} from "reactivestates";
import {opServicesModule} from "../angular-modules";
import {whenDebugging} from "../helpers/debug_output";
import {initStates} from "../helpers/reactive-fassade";
import {RelationsStateValue} from "./wp-relations/wp-relations.service";


/* /api/v3/work_packages */
export class WorkPackageStates extends Component {

  /* /:id/relations */
  relations = inputStateCache<RelationsStateValue>();

}


const ctx = createNewContext();
const wpStates = ctx.create(WorkPackageStates);

whenDebugging(() => {
  wpStates.enableLog(true);
});

opServicesModule.value('wpStates', wpStates);

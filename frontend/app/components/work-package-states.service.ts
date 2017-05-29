import {multiInput, createNewContext, StatesGroup} from "reactivestates";
import {opServicesModule} from "../angular-modules";
import {whenDebugging} from "../helpers/debug_output";
import {RelationsStateValue} from "./wp-relations/wp-relations.service";


/* /api/v3/work_packages */
export class WorkPackageStates extends StatesGroup {

  /* /:id/relations */
  relations = multiInput<RelationsStateValue>();

}


const ctx = createNewContext();
const wpStates = ctx.create(WorkPackageStates);

whenDebugging(() => {
  wpStates.enableLog(true);
});

opServicesModule.value('wpStates', wpStates);

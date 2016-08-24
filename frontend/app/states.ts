import {MultiState, initStates} from "./helpers/reactive-fassade";
import {WorkPackageResource} from "./components/api/api-v3/hal-resources/work-package-resource.service";



export const states = {

  workPackages: new MultiState<WorkPackageResource>()

};

initStates(states, (msg: any) => console.trace(msg));

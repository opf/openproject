import {MultiState, initStates} from "./helpers/reactive-fassade";
import {WorkPackageResource} from "./components/api/api-v3/hal-resources/work-package-resource.service";


export const states = {

  workPackages: new MultiState<WorkPackageResource>()

};

initStates(states, function (msg: any) {
  // RR: stupid hack to avoid compiler error
  (console.trace as any)(msg);
});

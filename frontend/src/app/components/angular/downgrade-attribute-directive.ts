
// Based on wrapper by @banjankri
// https://github.com/angular/angular/issues/16695#issuecomment-336456199
import {downgradeComponent} from "@angular/upgrade/static";

export function downgradeAttributeDirective(componentClass:new(...args:any[]) => any) {
  const wrapper = function($compile:any, $injector:any, $parse:any) {
    const factory = downgradeComponent({ component: componentClass });
    const component = factory($compile, $injector, $parse);
    component.restrict = "AE";
    return component;
  };
  wrapper.$inject = ["$compile", "$injector", "$parse"];
  return wrapper;
}


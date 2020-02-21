import "reflect-metadata";
import {Injector} from "@angular/core";
import {debugLog} from "core-app/helpers/debug_output";
import {prop} from "@uirouter/core";

export interface InjectableClass {
  injector:Injector;
}

export function InjectField() {
  return (target:InjectableClass, property:string) => {
    if (delete (target as any)[property]) {
      Object.defineProperty(target, property, {
        get: function(this:InjectableClass) {
          const type = Reflect.getMetadata('design:type', target, property);
          return this.injector.get<any>(type);
        },
        set: function(this:InjectableClass, val:any) {
          debugLog("Trying to set InjectField property " + property);
        }
      });
    }
  };
};
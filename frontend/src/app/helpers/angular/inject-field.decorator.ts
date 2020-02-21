import "reflect-metadata";
import {Injector} from "@angular/core";
import {debugLog} from "core-app/helpers/debug_output";

export interface InjectableClass {
  injector:Injector;
}

export function InjectField(token?:any, defaultValue:any = null) {
  return (target:InjectableClass, property:string) => {
    if (delete (target as any)[property]) {
      Object.defineProperty(target, property, {
        get: function(this:InjectableClass) {
          if (token) {
            return this.injector.get<any>(token, defaultValue);
          } else {
            const type = Reflect.getMetadata('design:type', target, property);
            return this.injector.get<any>(type);
          }
        },
        set: function(this:InjectableClass, _val:any) {
          debugLog("Trying to set InjectField property " + property);
        }
      });
    }
  };
};
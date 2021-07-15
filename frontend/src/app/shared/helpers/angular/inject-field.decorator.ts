import 'reflect-metadata';
import { InjectFlags, Injector } from '@angular/core';
import { debugLog } from 'core-app/shared/helpers/debug_output';

export interface InjectableClass {
  injector:Injector;
}

export function InjectField(token?:any, defaultValue:any = null, flags?:InjectFlags) {
  return (target:InjectableClass, property:string) => {
    // eslint-ignore-next-line no-param-reassign
    if (delete (target as any)[property]) {
      Object.defineProperty(target, property, {
        get(this:InjectableClass) {
          if (token) {
            return this.injector.get<any>(token, defaultValue, flags);
          }
          const type = Reflect.getMetadata('design:type', target, property);
          return this.injector.get<any>(type, defaultValue, flags);
        },
        set(this:InjectableClass) {
          debugLog(`Trying to set InjectField property ${property}`);
        },
      });
    }
  };
}

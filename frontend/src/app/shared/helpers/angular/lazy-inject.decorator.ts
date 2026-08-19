import 'reflect-metadata';
import { InjectOptions, Injector, ProviderToken } from '@angular/core';
import { debugLog } from 'core-app/shared/helpers/debug_output';

export interface InjectableClass {
  injector:Injector;
}

export function LazyInject<T = unknown>(
  token?:ProviderToken<T>,
  defaultValue:T | null = null,
  options?:InjectOptions,
) {
  return (target:InjectableClass, property:string):void => {
    if (delete (target as unknown as Record<string, unknown>)[property]) {
      Object.defineProperty(target, property, {
        get(this:InjectableClass):T | null {
          // When no token is given, fall back to the property's reflected
          // design type (requires emitDecoratorMetadata).
          const resolvedToken = (token
            ?? Reflect.getMetadata('design:type', target, property)) as ProviderToken<T>;
          return this.injector.get(resolvedToken, defaultValue, options);
        },
        set(this:InjectableClass):void {
          debugLog(`Trying to set LazyInject property ${property}`);
        },
      });
    }
  };
}

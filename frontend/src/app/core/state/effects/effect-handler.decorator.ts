import 'reflect-metadata';
import { debugLog } from 'core-app/shared/helpers/debug_output';
import { UntilDestroyedMixin } from 'core-app/shared/helpers/angular/until-destroyed.mixin';
import { untilComponentDestroyed } from '@w11k/ngx-componentdestroyed';
import { Action } from '@datorama/akita-ng-effects/lib/types';
import { ActionsService } from 'core-app/core/state/actions/actions.service';
import { ActionCreator } from 'ts-action/action';
import { Injector } from '@angular/core';

// We're opening a baseclass through the decorator, the decorator enforces using any */
/* eslint-disable @typescript-eslint/no-explicit-any */
/* eslint-disable @typescript-eslint/no-unsafe-member-access */
/* eslint-disable no-param-reassign */

export interface EffectClass extends UntilDestroyedMixin {
  injector:Injector;
}
const EffectHandlers = Symbol('EffectHandlers');

type EffectHandlerItem = { callback:(action:Action) => void, action:ActionCreator };

export function EffectHandler<T extends { new(...args:any[]):EffectClass }>(constructor:T):any {
  return class extends constructor {
    constructor(...args:any[]) {
      super(...args);
      const handlers = constructor.prototype[EffectHandlers] as Map<string, EffectHandlerItem>;
      if (handlers) {
        handlers.forEach((item:EffectHandlerItem, key:string) => {
          debugLog(`Subscribing to effect ${key}`);

          const actions$ = this.injector.get(ActionsService);

          actions$
            .ofType(item.action)
            .pipe(untilComponentDestroyed(this))
            .subscribe((instance) => {
              try {
                item.callback.call(this, instance);
              } catch (e) {
                // eslint-disable-next-line @typescript-eslint/restrict-template-expressions
                console.error(`Error thrown in effect callback ${key}: ${e}`);
              }
            });
        });
      }
    }
  };
}

export function EffectCallback(action:ActionCreator) {
  // eslint-disable-next-line @typescript-eslint/explicit-module-boundary-types
  return (target:any, property:string, descriptor:PropertyDescriptor):void => {
    if (!target[EffectHandlers]) {
      target[EffectHandlers] = new Map();
    }

    // Here we just add some information that class decorator will use
    // eslint-disable-next-line @typescript-eslint/no-unsafe-call
    target[EffectHandlers].set(property, { action, callback: descriptor.value as (action:Action) => void });
  };
}

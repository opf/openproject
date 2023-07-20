import 'reflect-metadata';
import { debugLog } from 'core-app/shared/helpers/debug_output';
import { ActionsService } from 'core-app/core/state/actions/actions.service';
import { ActionCreator } from 'ts-action/action';
import { Action } from 'ts-action';
import { takeWhile } from 'rxjs/operators';
import { UntilDestroyedMixin } from 'core-app/shared/helpers/angular/until-destroyed.mixin';
import { Observable } from 'rxjs';

/**
 * This interface specifies a constraint on the classes that can
 * be used as an @EffectHandler.
 *
 * As we depend on the ActionsService, we need that as a public property.
 */
export interface EffectClass {
  actions$:ActionsService;
  ngOnDestroy?():void;
}


const EffectHandlers = Symbol('EffectHandlers');

type EffectHandlerItem = { callback:(action:Action) => void, action:ActionCreator };

interface DecoratedEffectClass {
  [EffectHandlers]:Map<string, EffectHandlerItem>
}

export function registerEffectCallbacks(instance:EffectClass, untilDestroyed:(source:Observable<unknown>) => Observable<unknown>):void {
  // Access the handlers registered in the @EffectCallback method decorator
  // We're accessing a separate symbol on the base class that is not present
  // eslint-disable-next-line @typescript-eslint/no-unsafe-member-access
  const handlers = (instance as unknown as DecoratedEffectClass)[EffectHandlers];
  if (handlers) {
    handlers.forEach((item:EffectHandlerItem, key:string) => {
      debugLog(`[${instance.constructor.name}] Subscribing to effect ${key}`);

      // Subscribe to the specified action for the duration of this service's life.
      instance.actions$
        .ofType(item.action)
        .pipe(
          untilDestroyed,
        )
        .subscribe((action) => {
          // Wrap callback in a try-catch to avoid completing the subscription.
          try {
            item.callback.call(instance, action);
          } catch (e) {
            console.error(`Error thrown in effect callback ${key}: ${e as string}`);
          }
        });
    });
  }
}

/**
 * The EffectHandler decorates a class to be used for effects callbacks
 * To use, add it to a store service like so
 *
 * ```
 * @Injectable()
 * @EffectHandler
 * export class FooStoreService {
 *   @EffectCallback(someActionName)
 *   private actionCallback(action:ReturnType<typeof someActionName>) {
 *     // Effect callback for the given action
 *   }
 * }
 */
/* The class decorator requires any[] args to it to function */

/* eslint-disable-next-line @typescript-eslint/no-explicit-any */
export function EffectHandler<T extends { new(...args:any[]):EffectClass }>(constructor:T):any {
  return class extends constructor {
    private serviceDestroyed = false;

    /* The class decorator requires any[] args to it to function */
    /* eslint-disable-next-line @typescript-eslint/no-explicit-any */
    constructor(...args:any[]) {
      super(...args);

      registerEffectCallbacks(this, takeWhile(() => !this.serviceDestroyed));
    }

    ngOnDestroy():void {
      this.serviceDestroyed = true;
      if (super.ngOnDestroy) {
        super.ngOnDestroy();
      }
    }
  };
}

/**
 * The EffectCallback decorates a method of a `@EffectHandler` decorated class
 * to be used for effects callbacks.
 *
 * The decorator subscribes to the actionService for the given service for
 * the lifetime of the service.
 *
 * Example:
 *
 * ```
 * @Injectable()
 * @EffectHandler
 * export class FooStoreService {
 *   @EffectCallback(someActionName)
 *   private actionCallback(action:ReturnType<typeof someActionName>) {
 *     // Effect callback for the given action
 *   }
 * }
 */
export function EffectCallback(action:ActionCreator) {
  // eslint-disable-next-line @typescript-eslint/explicit-module-boundary-types
  return (service:unknown, property:string, descriptor:PropertyDescriptor):void => {
    const target = service as { [EffectHandlers]:Map<string, EffectHandlerItem> };
    if (!target[EffectHandlers]) {
      // We're assigning the symbol property in the base class
      // eslint-disable-next-line @typescript-eslint/no-unsafe-assignment,no-param-reassign
      target[EffectHandlers] = new Map();
    }

    // Here we just add some information that class decorator will use
    // eslint-disable-next-line @typescript-eslint/no-unsafe-call
    target[EffectHandlers].set(property, { action, callback: descriptor.value as (action:Action) => void });
  };
}

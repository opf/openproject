---
sidebar_navigation:
  title: State management
description: Get an overview of how frontend state management works
keywords: state management, stores, input states
---

# Development concept: State management

State management in complex frontend applications is a topic that has been heavily evolving over the past years. OpenProject is an old application, so its frontend existed long before stores and one-way data flow became popular, and several generations of state management now live side by side.

## Key takeaways

_State management in OpenProject frontend..._

- is historically controlled by `RxJS` and the [`@openproject/reactivestates`](https://github.com/opf/reactivestates) library, which this document describes in detail
- also uses [Akita](https://github.com/salesforce/akita) entity stores in `core/state` for API resources, and Angular Signals in newer components
- `State` and `InputState` are mostly syntactic sugar over RxJS `Subject` and `BehaviorSubject`
- States are used to hold and cache values with their values and non-values being observable

## Choosing an approach for new code

> [!NOTE]
> This page describes `reactivestates` for existing code. For new code, follow the choices below. Akita entity stores remain the current option for shared API resources in Angular code, but Akita is no longer maintained and the frontend is moving towards Hotwire.

- **Server-rendered UI with Hotwire and Primer.** For new screens and features, render HTML in Rails with Primer ViewComponents and add behaviour with Stimulus. State then lives on the server and in the DOM, not in a frontend store. See [Using Hotwire with ViewComponents](../hotwire-view-components) and [Stimulus](../stimulus).
- **Signals in existing Angular screens.** New Angular components are still fine where they integrate with existing Angular screens, such as the work package table or work package editing. Hold component and local state in Signals (`signal`, `computed`, signal inputs) wherever RxJS is not the right mental model, and keep RxJS for streams of events and requests.
- **Akita entity stores in `core/state`.** For API resources shared across Angular components, use a [`ResourceStoreService`](https://github.com/opf/openproject/tree/dev/frontend/src/app/core/state/resource-store.service.ts) subclass such as `ProjectsResourceService`, following the entity store rules in the [frontend style guide](../../style-guide/frontend/).
- **`reactivestates`.** Use it only when working on existing code built around it, such as the `States` cache or the work package query space.

## InputState

An `InputState` object is a wrapper around RxJS [`BehaviorSubject`](https://rxjs.dev/api/index/class/BehaviorSubject). It provides some syntactic sugar over it to inspect values and provide helpers to observe streams and fill in the underlying `Subject`.

To create an `InputState`, call `new InputState<Type>(initialValue:Type|undefined)` or use the helper method `input<Type>(initialValue?:Type)` which will fall back to the undefined value. You will then be able to inspect its value and contents.

```typescript
// An initially empty state
const state = input<string>();

console.log(state.isPristine()); // true
console.log(state.hasValue()); // false
console.log(state.value); // undefined
```

An InputState will hold exactly one value, that you can fill explicitly:

```typescript
state.putValue('my value');

console.log(state.isPristine()); // false
console.log(state.hasValue()); // true
console.log(state.value); // 'my value'
```

You can find out if a value is older than a specific amount of ms:

```typescript
state.isValueOlderThan(60000); // Value is older than 60 seconds?
```

The value can be explicitly cleared with `state.clear()`.

You can also fill the InputState with the result of a promise request. With `putFromPromiseIfPristine`, the promise will only be requested if the state is empty. This is useful for performing API requests that should not be re-executed while the value is cached.

```typescript
state.putFromPromiseIfPristine(() => Promise.resolve('my new value'));
```

To find out if there is an active promise request, use `state.hasActivePromiseRequest()`. You can also explicitly clear and put from promise in one step:

```typescript
state.clearAndPutFromPromise(Promise.resolve('overridden value'));
```

You can get an RxJS `Observable` to the value stream with `state.values$()`:

```typescript
state
  .values$()
  .subscribe(val => console.log("Observed value " + val));
```

You can also observe the `changes` which includes undefined values

```typescript
state
  .changes$()
  .subscribe(val => console.log("Observed " + (val ? "String value" : "Undefined")));
```

## MultiInputState

The `MultiInputState` is basically a map with a string key and an `InputState` as its value. It is used for most of the cache stores in OpenProject.

To create a `MultiInputState`, use the helper method `multiInput<Type>()` . To get an `InputState` member of this map, use the following:

```typescript
export type FooType = { id:number };
const multi = multiInput<FooType>();
const state = multi.get('my identifier');
state.putValue({ id: 1234 });

// Later on
multi.get('my identifier').value // { id: 1234 }
```

The MultiInputState can be observed as a whole:

```typescript
multi
  .observeChange()
  .subscribe(([changedId, foo]) => {
    console.log(`CHANGE for ${changedId}: ${foo?.id ?? 'cleared'}`);
  });

multi.get('my identifier').clear();
// CHANGE for my identifier: cleared

multi
  .get('my identifier')
  .putFromPromiseIfPristine(() => Promise.resolve({ id: 5678 }));

// CHANGE for my identifier: 5678
```

## StatesGroup

The `StatesGroup` aggregates multiple States or MultiInputStates into one class. The only benefit to this is debugging capabilities of the reactivestates library. You can call the following method in development mode to see all changes to states in a StateGroup logged to console:

```typescript
import { enableReactiveStatesLogging } from '@openproject/reactivestates';

enableReactiveStatesLogging();
```

This might then look like the following, with green color for added objects, and red color for removed values:

```text
[RS] Changesets.changesets[/api/v3/projects/1] {o=4} "[object Object]"
```

## 🔗 Code references

- [`States`](https://github.com/opf/openproject/blob/dev/frontend/src/app/core/states/states.service.ts) Global `StatesGroup` cache of MultiInputStates
- [`IsolatedQuerySpace`](https://github.com/opf/openproject/blob/dev/frontend/src/app/features/work-packages/directives/query-space/isolated-query-space.ts) Query space `StatesGroup`. Is instantiated multiple times whenever a work package query is loaded. See [the separate concept guide](../queries) for more information.
- [`@openproject/reactivestates`](https://github.com/opf/reactivestates) library we use for the StatesGroup. This was developed by Roman primarily for us during AngularJS times and is now maintained by OpenProject.
- [`ResourceStoreService`](https://github.com/opf/openproject/tree/dev/frontend/src/app/core/state/resource-store.service.ts) the base class for the Akita entity stores in `core/state`

## Discussions

- In contrast to a `Store` concept of redux, the States and state groups do not have any concept of data immutability. As a caller you will need to ensure that. In OpenProject, many of the states are in fact mutable due to historic reasons and the fact that complex class instances are passed around that cannot be easily shallow copied. This will need to be refactored in the future.
- As the `reactivestates` library was primarily developed for us, OpenProject has taken over its code and publishes it as `@openproject/reactivestates`. Akita was adopted alongside it for entity stores, but is itself no longer maintained. See [Choosing an approach for new code](#choosing-an-approach-for-new-code) for where new state should live.

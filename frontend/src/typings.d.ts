/// <reference path="../tests/typings/tests.d.ts" />
// Explicitly add UiRouterRx typings (in order to use params$ type)
// https://github.com/ui-router/angular/issues/166
/// <reference path="../node_modules/@uirouter/rx/lib/core.augment.d.ts" />
/* SystemJS module definition */
declare let module:NodeModule;
declare module 'dom-plane' {
  export function createPointCB(point:any):any;
  export function getClientRect(el:Element|Window):{ top:number, bottom:number, left:number, right:number };
  export function pointInside(point:any, el:Element|Window):any;
}

interface NodeModule {
  id:string;
}

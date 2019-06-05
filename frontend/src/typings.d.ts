/// <reference path="../tests/typings/tests.d.ts" />

/* SystemJS module definition */
declare var module:NodeModule;
declare module 'dom-plane' {
  export function createPointCB(point:any):any;
  export function getClientRect(el:Element|Window):any;
  export function pointInside(point:any, el:Element|Window):any;
}

interface NodeModule {
  id:string;
}


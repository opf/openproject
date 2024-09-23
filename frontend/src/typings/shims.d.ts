// Declare some globals
// to work around previously magical global constants
// provided by typings@global

// Active issue
// https://github.com/Microsoft/TypeScript/issues/10178

/// <reference path="../../node_modules/@types/jquery/index.d.ts" />
/// <reference path="../../node_modules/@types/jqueryui/index.d.ts" />
/// <reference path="../../node_modules/@types/mousetrap/index.d.ts" />
/// <reference path="../../node_modules/@types/moment-timezone/index.d.ts" />
/// <reference path="../../node_modules/@types/urijs/index.d.ts" />
/// <reference path="../../node_modules/@types/webpack-env/index.d.ts" />
/// <reference path="../../node_modules/@types/dragula/index.d.ts" />
/// <reference path="../../node_modules/@types/resize-observer-browser/index.d.ts" />

import { Injector } from '@angular/core';

import { OpenProject } from 'core-app/core/setup/globals/openproject';
import * as TLodash from 'lodash';
import { Dragula } from 'dragula';
import { Screenfull } from 'screenfull';
import { ErrorReporterBase } from 'core-app/core/errors/error-reporter-base';
import { I18n } from 'i18n-js';
import '@hotwired/turbo';

declare module 'observable-array';
declare module 'dom-autoscroller';
declare module 'core-vendor/enjoyhint';

declare module '@hotwired/turbo' {
  interface BrowserAdapter {
    formSubmissionStarted:() => void;
    formSubmissionFinished:() => void;
  }

  export const session:{
    drive:boolean;
    adapter:BrowserAdapter;
  };

  export const navigator:{
    submitForm:(form:HTMLFormElement, submitter?:HTMLElement) => void;
  };

  export interface StreamElement {
    templateElement:HTMLTemplateElement;
  }

  export function start():void;
}

declare global {
  const _:typeof TLodash;
  const I18n:I18n;
  const dragula:Dragula;
}

declare global {
  interface Window {
    I18n:I18n;
    appBasePath:string;
    ng2Injector:Injector;
    OpenProject:OpenProject;
    ErrorReporter:ErrorReporterBase;
    onboardingTourInstance:any;
    screenfull:Screenfull;
    MiniProfiler?:{ pageTransition:() => void };
  }

  interface JQuery {
    topShelf:any;
    mark:any;
    tablesorter:any;
  }

  interface JQueryStatic {
    metadata:any;
    tablesorter:any;
  }
}

export {};

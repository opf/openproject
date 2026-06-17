// Declare some globals
// to work around previously magical global constants
// provided by typings@global

// Active issue
// https://github.com/Microsoft/TypeScript/issues/10178

/// <reference path="../../node_modules/@types/mousetrap/index.d.ts" />
/// <reference path="../../node_modules/@types/moment-timezone/index.d.ts" />
/// <reference path="../../node_modules/@types/urijs/index.d.ts" />
/// <reference path="../../node_modules/@types/resize-observer-browser/index.d.ts" />

import { Injector } from '@angular/core';

import { OpenProject } from 'core-app/core/setup/globals/openproject';
import * as TLodash from 'lodash';
import { Screenfull } from 'screenfull';
import { ErrorReporterBase } from 'core-app/core/errors/error-reporter-base';
import { I18n } from 'i18n-js';

declare module 'observable-array';
declare module 'dom-autoscroller';
declare module 'core-vendor/enjoyhint';

declare global {
  const _:typeof TLodash;
  const I18n:I18n;

  // Public path prefix used to build absolute asset URLs at runtime.
  // Set once in main.ts; read by the image/video path helpers.
  var publicAssetPath:string;
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
    tablesorter:any;
  }

  interface JQueryStatic {
    metadata:any;
    tablesorter:any;
  }
}

export {};

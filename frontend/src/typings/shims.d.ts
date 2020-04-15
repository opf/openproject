// Declare some globals
// to work around previously magical global constants
// provided by typings@global

// Active issue
// https://github.com/Microsoft/TypeScript/issues/10178

/// <reference path="../../node_modules/@types/angular-mocks/index.d.ts" />
/// <reference path="../../node_modules/@types/jasmine/index.d.ts" />
/// <reference path="../../node_modules/@types/jquery/index.d.ts" />
/// <reference path="../../node_modules/@types/jqueryui/index.d.ts" />
/// <reference path="../../node_modules/@types/mousetrap/index.d.ts" />
/// <reference path="../../node_modules/@types/moment-timezone/index.d.ts" />
/// <reference path="../../node_modules/@types/urijs/index.d.ts" />
/// <reference path="../../node_modules/@types/webpack-env/index.d.ts" />
/// <reference path="../../node_modules/@types/es6-shim/index.d.ts" />
/// <reference path="../../node_modules/@types/dragula/index.d.ts" />

import {ErrorReporter} from "core-app/sentry/sentry-reporter";
import {Injector} from '@angular/core';

import {OpenProject} from 'core-app/globals/openproject';
import * as TLodash from 'lodash';
import * as TMoment from 'moment';
import * as TSinon from 'sinon';
import {GlobalI18n} from "core-app/modules/common/i18n/i18n.service";
import {Dragula} from "dragula";

declare module 'dom-autoscroller';

declare global {
  const _:typeof TLodash;
  const sinon:typeof TSinon;
  const moment:typeof TMoment;
  const bowser:any;
  const I18n:GlobalI18n;
  const dragula:Dragula;

  declare const require:any;
  declare const describe:any;
  declare const beforeEach:any;
  declare const afterEach:any;
  declare const after:any;
  declare const before:any;
  declare const it:(desc:string, callback:(done:() => void) => void) => void;

}

declare global {
  interface Window {
    appBasePath:string;
    ng2Injector:Injector;
    OpenProject:OpenProject;
    ErrorReporter:ErrorReporter;
  }

  interface JQuery {
    topShelf:any;
    mark:any;
  }
}

export {};

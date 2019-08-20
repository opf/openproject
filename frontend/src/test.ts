// This file is required by karma.conf.js and loads recursively all the .spec and framework files

// Require the reflect ES7 polyfill for JIT
import 'zone.js/dist/zone';  // Included with Angular CLI.
import 'core-js/es/reflect';

import 'zone.js/dist/zone-testing';
import { getTestBed } from '@angular/core/testing';
import {
  BrowserDynamicTestingModule,
  platformBrowserDynamicTesting
} from '@angular/platform-browser-dynamic/testing';
import {GlobalI18n} from "core-app/modules/common/i18n/i18n.service";
import {I18nShim} from "./test/i18n-shim";

require('expose-loader?_!lodash');

declare const require:any;
declare global {
  interface Window {
    I18n:GlobalI18n;
  }
}

// Declare global I18n shim
window.I18n = new I18nShim();


// First, initialize the Angular testing environment.
getTestBed().initTestEnvironment(
  BrowserDynamicTestingModule,
  platformBrowserDynamicTesting()
);

// Then we find all the tests.
const context = require.context('./', true, /\.spec\.ts$/);
// And load the modules.
context.keys().map(context);

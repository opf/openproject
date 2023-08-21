// This file is required by karma.conf.js and loads recursively all the .spec and framework files

// Require the reflect ES7 polyfill for JIT
import 'zone.js'; // Included with Angular CLI.
import 'core-js/es/reflect';

import 'zone.js/testing';
import { getTestBed } from '@angular/core/testing';
import {
  BrowserDynamicTestingModule,
  platformBrowserDynamicTesting,
} from '@angular/platform-browser-dynamic/testing';
import { GlobalI18n } from 'core-app/core/i18n/i18n.service';
import { I18nShim } from './test/i18n-shim';

// eslint-disable-next-line @typescript-eslint/no-unsafe-member-access no-explicit-any
(window as any).global = window;

require('expose-loader?_!lodash');
declare global {
  export interface Window {
    I18n:GlobalI18n;
  }
}

// Declare global I18n shim
window.I18n = new I18nShim();

// First, initialize the Angular testing environment.
getTestBed().initTestEnvironment(
  BrowserDynamicTestingModule,
  platformBrowserDynamicTesting(),
  {
    teardown: { destroyAfterEach: false },
  },
);

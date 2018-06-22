// This file is required by karma.conf.js and loads recursively all the .spec and framework files


import 'zone.js/dist/zone-testing';
import { getTestBed } from '@angular/core/testing';
import {
  BrowserDynamicTestingModule,
  platformBrowserDynamicTesting
} from '@angular/platform-browser-dynamic/testing';

declare const require:any;

// First, initialize the Angular testing environment.
getTestBed().initTestEnvironment(
  BrowserDynamicTestingModule,
  platformBrowserDynamicTesting()
);

// import 'angular-mocks';
// import './app/init-vendors';
// import './app/init-globals';
// import './app/globals/browser-specific-flags';
// import './app/globals/top-shelf';
// import './app/globals/unsupported-browsers';


// require('expose-loader?sinon/lib/sinon.js');
// require('expose-loader?sinon-chai/lib/sinon-chai.js');


// Then we find all the tests.
const context = require.context('./', true, /\.spec\.ts$/);
// And load the modules.
context.keys().map(context);

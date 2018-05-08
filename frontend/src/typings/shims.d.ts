// Declare some globals
// to work around previously magical global constants
// provided by typings@global

// Active issue
// https://github.com/Microsoft/TypeScript/issues/10178

import * as TLodash from 'lodash';
import * as TAngular from 'angular';
import * as TSinon from 'sinon';
import * as TMoment from 'moment';
import {OpenProject} from 'core-app/globals/openproject';
import {Injector} from '@angular/core';

declare global {
  const _:typeof TLodash;
  const angular:typeof TAngular;
  const sinon:typeof TSinon;
  const moment:typeof TMoment;
  const bowser:any;

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
  }
}

export {};

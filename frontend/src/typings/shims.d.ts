//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) the OpenProject GmbH
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2013 Jean-Philippe Lang
// Copyright (C) 2010-2013 the ChiliProject Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

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
import { Screenfull } from 'screenfull';
import { ErrorReporterBase } from 'core-app/core/errors/error-reporter-base';
import { I18n } from 'i18n-js';

declare module 'observable-array';
declare module 'dom-autoscroller';
declare module 'core-vendor/enjoyhint';

declare global {
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

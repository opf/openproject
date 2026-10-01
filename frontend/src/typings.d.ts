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

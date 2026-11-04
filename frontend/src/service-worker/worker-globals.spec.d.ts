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
// along with this program. If not, see <https://www.gnu.org/licenses/>.
//
// See COPYRIGHT and LICENSE files for more details.
//++

// Specs compile against the DOM lib, so the worker types their imports need are declared here.
// They are written by hand because adding the WebWorker lib to the spec compile would expose
// every worker global to every app spec. The worker build checks the same code against the real lib.
interface WindowClient {
  readonly url:string;
  readonly focused:boolean;
  readonly visibilityState:DocumentVisibilityState;
  focus():Promise<WindowClient>;
  navigate(url:string):Promise<WindowClient|null>;
}

interface ServiceWorkerGlobalScope {
  readonly location:Location;
  readonly registration:ServiceWorkerRegistration;
  readonly clients:{
    matchAll(options?:{ type?:'window'; includeUncontrolled?:boolean }):Promise<WindowClient[]>;
    openWindow(url:string):Promise<WindowClient|null>;
  };
}

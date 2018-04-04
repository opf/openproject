//-- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See doc/COPYRIGHT.rdoc for more details.
//++

import {opApiModule} from '../../../../angular-modules';
import {HalResource} from './hal-resource.service';
import {WorkPackageResourceInterface} from 'core-components/api/api-v3/hal-resources/work-package-resource.service';

interface CustomActionResourceEmbedded {
}

export interface CustomActionResourceLinks extends CustomActionResourceEmbedded {
  self():ng.IPromise<CustomActionResourceInterface>;
  executeImmediately(payload:any):ng.IPromise<WorkPackageResourceInterface>;
}

export class CustomActionResource extends HalResource {
  public $embedded:CustomActionResourceEmbedded;
  public id:number;
  public name:string;
  public description:string;
}

function customActionResource() {
  return CustomActionResource;
}

export interface CustomActionResourceInterface extends CustomActionResourceLinks, CustomActionResourceEmbedded, CustomActionResource {
}

opApiModule.factory('CustomActionResource', customActionResource);

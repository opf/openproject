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

import {CollectionResource} from './collection-resource.service';
import {WorkPackageResourceInterface} from './work-package-resource.service';
import {HalResource} from './hal-resource.service';
import {opApiModule} from '../../../../angular-modules';

interface WorkPackageCollectionResourceEmbedded {
  schemas: CollectionResource;
  elements: WorkPackageResourceInterface[];
  groups: GroupObject[];
}

export class WorkPackageCollectionResource extends CollectionResource {
  public schemas: CollectionResource;
  public createWorkPackage:any;
  public elements: WorkPackageResourceInterface[];
  public groups: GroupObject[];
  public totalSums?: Object;
  public sumsSchema?: HalResource;
  public representations: Array<HalResource>;
}

export interface WorkPackageCollectionResourceInterface extends WorkPackageCollectionResourceEmbedded, WorkPackageCollectionResource {
}

/**
 * A reference to a group object as returned from the API.
 * Augmented with state information such as collapsed state.
 */
export interface GroupObject {
  value:any;
  count:number;
  collapsed?:boolean;
  index:number;
  identifier:string;
  href:{ href:string }[];
  _links: {
    valueLink: { href:string }[];
    groupBy: { href:string };
  }
}

function workPackageCollectionResource() {
  return WorkPackageCollectionResource;
}

opApiModule.factory('WorkPackageCollectionResource', workPackageCollectionResource);

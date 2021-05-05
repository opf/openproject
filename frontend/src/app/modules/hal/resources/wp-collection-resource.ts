//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2021 the OpenProject GmbH
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
// See docs/COPYRIGHT.rdoc for more details.
//++

import { WorkPackageResource } from 'core-app/modules/hal/resources/work-package-resource';
import { CollectionResource } from 'core-app/modules/hal/resources/collection-resource';
import { SchemaResource } from 'core-app/modules/hal/resources/schema-resource';
import { HalResource } from 'core-app/modules/hal/resources/hal-resource';

export interface WorkPackageCollectionResourceEmbedded {
  elements:WorkPackageResource[];
  groups:GroupObject[];
}

export class WorkPackageCollectionResource extends CollectionResource<WorkPackageResource> {
  public schemas:CollectionResource<SchemaResource>;
  public createWorkPackage:any;
  public elements:WorkPackageResource[];
  public groups:GroupObject[];
  public totalSums?:{[key:string]:number};
  public sumsSchema?:SchemaResource;
  public representations:Array<HalResource>;
}

export interface WorkPackageCollectionResource extends WorkPackageCollectionResourceEmbedded {}

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
  sums:{[attribute:string]:number|null};
  href:{ href:string }[];
  _links:{
    valueLink:{ href:string }[];
    groupBy:{ href:string };
  };
}

// -- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2022 the OpenProject GmbH
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
// See COPYRIGHT and LICENSE files for more details.
//++

import { ID } from '@datorama/akita';
import { IHalResourceLink, IHalResourceLinks } from 'core-app/core/state/hal-resource';
import { IHALCollection } from 'core-app/core/apiv3/types/hal-collection.type';

export class StorageCollection implements IHALCollection<IStorage> {
  readonly _type:'Collection';

  readonly _embedded:{ elements:IStorage[] } = { elements: [] };

  readonly count:number;

  readonly offset:number;

  readonly pageSize:number;

  readonly total:number;

  constructor(storages:IStorage[]) {
    this._embedded.elements = storages;
    this.count = storages.length;
    this.offset = 0;
    this.pageSize = 1;
    this.total = storages.length;
  }
}

export interface IStorageHalResourceLinks extends IHalResourceLinks {
  self:IHalResourceLink;
  type:IHalResourceLink;
  origin:IHalResourceLink;
  connectionState:IHalResourceLink;
}

export interface IStorage {
  id:ID;
  name:string;
  createdAt?:string;
  lastModifiedAt?:string;

  _links:IStorageHalResourceLinks;
}

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

import { HalResource } from 'core-app/features/hal/resources/hal-resource';

export const queryColumnTypes = {
  PROPERTY: 'QueryColumn::Property',
  RELATION_OF_TYPE: 'QueryColumn::RelationOfType',
  RELATION_TO_TYPE: 'QueryColumn::RelationToType',
  RELATION_CHILD: 'QueryColumn::RelationChild',
};

/**
 * A reference to a query column object as returned from the API.
 */
export interface QueryColumn extends HalResource {
  id:string;
  name:string;
  /* eslint-disable-next-line @typescript-eslint/no-explicit-any */
  custom_field?:any;
  _links?:{
    self:{ href:string, title:string };
  };
}

export interface TypeRelationQueryColumn extends QueryColumn {
  type:{ href:string, name:string },
  _links?:{
    self:{ href:string, title:string },
    type:{ href:string, title:string }
  }
}

export interface RelationQueryColumn extends QueryColumn {
  relationType:string;
}

export function isRelationColumn(column:QueryColumn) {
  const relationTypes = [
    queryColumnTypes.RELATION_TO_TYPE,
    queryColumnTypes.RELATION_OF_TYPE,
    queryColumnTypes.RELATION_CHILD,
  ];
  return relationTypes.includes(column._type);
}

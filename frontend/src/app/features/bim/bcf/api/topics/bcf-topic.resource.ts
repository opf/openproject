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
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { jsonArrayMember, jsonMember, jsonObject } from 'typedjson';
import moment, { Moment } from 'moment';

@jsonObject
export class BcfTopicAuthorizationMap {
  @jsonArrayMember(String)
  topic_actions:string[];

  @jsonArrayMember(String)
  topic_status:string[];
}

@jsonObject
export class BcfTopicResource {
  @jsonMember(String)
  guid:string;

  @jsonMember(String)
  topic_type:string;

  @jsonMember(String)
  topic_status:string;

  @jsonMember(String)
  priority:string;

  @jsonArrayMember(String)
  reference_links:string[];

  @jsonMember(String)
  title:string;

  @jsonMember(Number, { preserveNull: true })
  index:number|null;

  @jsonArrayMember(String)
  labels:string[];

  @jsonMember({ deserializer: (value) => moment(value), serializer: (timestamp:Moment) => timestamp.toISOString() })
  creation_date:Moment;

  @jsonMember(String)
  creation_author:string;

  @jsonMember({ deserializer: (value) => moment(value), serializer: (timestamp:Moment) => timestamp.toISOString() })
  modified_date:Moment;

  @jsonMember(String, { preserveNull: true })
  modified_author:string|null;

  @jsonMember(String)
  assigned_to:string;

  @jsonMember(String, { preserveNull: true })
  stage:string|null;

  @jsonMember(String)
  description:string;

  @jsonMember({
    deserializer: (value) => moment(value),
    serializer: (timestamp:Moment) => timestamp.format('YYYY-MM-DD'),
  })
  due_date:Moment;

  @jsonMember(BcfTopicAuthorizationMap)
  authorization:BcfTopicAuthorizationMap;
}

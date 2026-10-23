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

import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { CallableHalLink } from 'core-app/features/hal/hal-link/hal-link';
import { RoleResource } from 'core-app/features/hal/resources/role-resource';
import { ProjectResource } from 'core-app/features/hal/resources/project-resource';
import Formattable = api.v3.Formattable;

export interface MembershipResourceLinks {
  update:CallableHalLink;
  updateImmediately:CallableHalLink;
  delete:CallableHalLink;
}

export interface MembershipResourceEmbedded {
  principal:HalResource;
  roles:RoleResource[];
  project:ProjectResource;
  notificationMessage:Formattable;
}

export class MembershipResource extends HalResource implements MembershipResourceLinks, MembershipResourceEmbedded {
  public update:CallableHalLink;

  public updateImmediately:CallableHalLink;

  public delete:CallableHalLink;

  public principal:HalResource;

  public roles:RoleResource[];

  public project:ProjectResource;

  public notificationMessage:Formattable;
}

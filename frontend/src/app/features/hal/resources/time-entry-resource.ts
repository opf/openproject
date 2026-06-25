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

import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { ProjectResource } from 'core-app/features/hal/resources/project-resource';
import { InputState } from '@openproject/reactivestates';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import Formattable = api.v3.Formattable;
import { MeetingResource } from 'core-app/features/hal/resources/meeting-resource';
import idFromLink from 'core-app/features/hal/helpers/id-from-link';
import { formatWorkPackageId } from 'core-app/shared/helpers/work-package-id-pattern';

export class TimeEntryResource extends HalResource {
  project:ProjectResource;

  activity:HalResource|null;

  comment:Formattable;

  entity:WorkPackageResource|MeetingResource;

  spentOn:string;

  ongoing:boolean;

  public get state():InputState<this> {
    return this.states.timeEntries.get(this.id!) as unknown as InputState<this>;
  }

  /**
   * Exclude the schema _link from the linkable Resources.
   */
  public $linkableKeys():string[] {
    return super.$linkableKeys().filter((key) => key !== 'schema');
  }
}

export interface TimeEntryResource {
  delete():Promise<unknown>;
}

export function formatTimeEntryEntityName(entity:WorkPackageResource|MeetingResource):string {
  const displayId = entity.$link?.displayId;
  const formattedId = displayId ? formatWorkPackageId(displayId) : `#${idFromLink(entity.href)}`;
  return `${formattedId}: ${entity.name}`;
}

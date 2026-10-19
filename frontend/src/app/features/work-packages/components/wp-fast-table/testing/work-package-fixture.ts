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

import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { RelationResource } from 'core-app/features/hal/resources/relation-resource';
import { RelationsStateValue } from 'core-app/features/work-packages/components/wp-relations/wp-relations.service';
import { GroupObject } from 'core-app/features/hal/resources/wp-collection-resource';
import { groupIdentifier } from '../builders/modes/grouped/grouped-rows-helpers';

export interface WorkPackageFixture {
  id:string;
  subject?:string;
  /** Further resource attributes, e.g. a linked `status` the table groups by. */
  attributes?:Record<string, unknown>;
  ancestors?:WorkPackageFixture[];
  /** The type name an `ofType` relation row shows as its label; defaults to `Task`. */
  type?:string;
  /** Child work packages a `children: true` column expands into child relation rows. */
  children?:WorkPackageFixture[];
}

/** A relation `from` → `to` of `type`; seen from `to` it reads as `reverseType` (default `type`). */
export interface RelationFixture {
  from:string;
  to:string;
  type:string;
  reverseType?:string;
}

export interface GroupFixture {
  value:string;
  href:string;
  count:number;
}

export function buildWorkPackage(fixture:WorkPackageFixture):WorkPackageResource {
  const subject = fixture.subject ?? `Work package ${fixture.id}`;
  const href = `/api/v3/work_packages/${fixture.id}`;

  return {
    type: { name: fixture.type ?? 'Task' },
    children: fixture.children?.map(buildWorkPackage),
    ...fixture.attributes,
    id: fixture.id,
    subject,
    href,
    $href: href,
    $links: { self: { href } },
    $source: { id: fixture.id, subject, _links: { self: { href } } },
    getAncestors: () => (fixture.ancestors ?? []).map(buildWorkPackage),
    subjectWithId: () => `#${fixture.id} ${subject}`,
  } as unknown as WorkPackageResource;
}

export function buildRelations(relations:RelationFixture[]):Map<string, RelationsStateValue> {
  const byWorkPackage = new Map<string, RelationsStateValue>();

  relations.forEach((fixture, index) => {
    const id = String(index);
    const relation = {
      id,
      denormalized: (workPackage:{ id:string|null }) => {
        const outgoing = workPackage.id === fixture.from;
        const targetId = outgoing ? fixture.to : fixture.from;
        const relationType = outgoing ? fixture.type : (fixture.reverseType ?? fixture.type);
        const reverseRelationType = outgoing ? (fixture.reverseType ?? fixture.type) : fixture.type;
        return {
          target: { id: targetId, href: `/api/v3/work_packages/${targetId}` },
          targetId,
          relationType,
          reverseRelationType,
        };
      },
    } as unknown as RelationResource;

    [fixture.from, fixture.to].forEach((workPackageId) => {
      byWorkPackage.set(workPackageId, { ...byWorkPackage.get(workPackageId), [id]: relation });
    });
  });

  return byWorkPackage;
}

export function buildGroup(fixture:GroupFixture, groupBy:string, index:number):GroupObject {
  const group = {
    value: fixture.value,
    count: fixture.count,
    collapsed: false,
    index,
    identifier: '',
    sums: null as unknown as GroupObject['sums'],
    href: [{ href: fixture.href }],
    _links: {
      valueLink: [{ href: fixture.href }],
      groupBy: { href: `/api/v3/queries/group_bys/${groupBy}` },
    },
  };

  return { ...group, identifier: groupIdentifier(group) };
}

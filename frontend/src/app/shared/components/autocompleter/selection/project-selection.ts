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

import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { HalResourceService } from 'core-app/features/hal/services/hal-resource.service';
import {
  IProjectAutocompleterData,
} from 'core-app/shared/components/autocompleter/project-autocompleter/project-autocompleter.component';
import { EntityId, decodeEntityReference, isEntityId } from 'core-app/shared/types/entity-reference';
import {
  compareByIdentity,
  decodeSingleEntity,
  entitySelectionToModel,
  halNameOf,
  invalidShape,
  readProperty,
  referenceSource,
  trackByIdentity,
} from './entity-selection';
import { DecodeResult, EntitySelection, SelectionAdapter } from './selection-adapter';

export type ProjectSelection = EntitySelection<IProjectAutocompleterData>|null;

interface ProjectFields {
  id:EntityId|null|undefined;
  name:string|undefined;
  href:string|null|undefined;
}

function fieldsOf(raw:object):ProjectFields|null {
  const id = readProperty(raw, 'id');
  const name = readProperty(raw, 'name');
  const href = readProperty(raw, 'href');

  if (!(id == null || isEntityId(id))) { return null; }
  if (!(name === undefined || typeof name === 'string')) { return null; }
  if (!(href == null || (typeof href === 'string' && href.length > 0))) { return null; }

  return { id, name, href };
}

function halFieldsOf(resource:HalResource):ProjectFields|null {
  return fieldsOf({
    id: resource.id ?? undefined,
    name: halNameOf(resource),
    href: resource.href,
  });
}

function classify({ id, name, href }:ProjectFields):DecodeResult<ProjectSelection> {
  if (id == null && !href) {
    if (name !== undefined) {
      return { ok: false, issue: { code: 'unsupported-selection' } };
    }
    return href === null ? { ok: true, value: null } : invalidShape;
  }

  if (id != null && name !== undefined && href) {
    return { ok: true, value: { kind: 'option', option: { id, name, href } } };
  }

  const reference = decodeEntityReference({
    ...(id != null && { id }),
    ...(href && { href }),
    ...(name !== undefined && { name }),
  });
  return reference ? { ok: true, value: { kind: 'reference', reference } } : invalidShape;
}

export function decodeProjectSelection(raw:unknown):DecodeResult<ProjectSelection> {
  return decodeSingleEntity<ProjectFields, IProjectAutocompleterData>(raw, { fieldsOf, halFieldsOf, classify });
}

export function createProjectSelectionAdapter():SelectionAdapter<ProjectSelection> {
  return new SelectionAdapter<ProjectSelection>(
    decodeProjectSelection,
    null,
    entitySelectionToModel,
    compareByIdentity,
    trackByIdentity,
  );
}

export function projectSelectionToResource(
  value:ProjectSelection,
  deps:{ halResourceService:HalResourceService; apiV3Service:ApiV3Service },
):HalResource|null {
  if (value === null) {
    return null;
  }

  switch (value.kind) {
    case 'option':
      return deps.halResourceService.createHalResourceOfType('project', { ...value.option });
    case 'reference':
      return deps.halResourceService.createHalResourceOfType('project', referenceSource(value.reference, (id) => deps.apiV3Service.projects.id(id).path));
  }
}

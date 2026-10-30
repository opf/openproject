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
  IUserAutocompleteItem,
} from 'core-app/shared/components/autocompleter/user-autocompleter/user-autocompleter.component';
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

export type UserSelection = EntitySelection<IUserAutocompleteItem>|null;

interface UserFields {
  id:EntityId|null|undefined;
  name:string|undefined;
  href:string|null|undefined;
  email:string|null|undefined;
  avatar:string|null|undefined;
}

function isOptionalText(value:unknown):value is string|null|undefined {
  return value == null || typeof value === 'string';
}

function fieldsOf(raw:object):UserFields|null {
  const id = readProperty(raw, 'id');
  const name = readProperty(raw, 'name');
  const href = readProperty(raw, 'href');
  const email = readProperty(raw, 'email');
  const avatar = readProperty(raw, 'avatar');

  if (!(id == null || isEntityId(id))) { return null; }
  if (!(name === undefined || typeof name === 'string')) { return null; }
  if (!(href == null || (typeof href === 'string' && href.length > 0))) { return null; }
  if (!isOptionalText(email) || !isOptionalText(avatar)) { return null; }

  return { id, name, href, email, avatar };
}

function halFieldsOf(resource:HalResource):UserFields|null {
  return fieldsOf({
    id: resource.id ?? undefined,
    name: halNameOf(resource),
    href: resource.href,
    email: readProperty(resource, 'email'),
    avatar: readProperty(resource, 'avatar'),
  });
}

function classify(fields:UserFields):DecodeResult<UserSelection> {
  const { id, name, href, email, avatar } = fields;

  if (id == null && !href) {
    if (name !== undefined) {
      return { ok: false, issue: { code: 'unsupported-selection' } };
    }
    return href === null ? { ok: true, value: null } : invalidShape;
  }

  if (id != null && name !== undefined && href !== undefined) {
    const option:IUserAutocompleteItem = {
      id,
      name,
      href,
      ...(email !== undefined && { email }),
      ...(avatar !== undefined && { avatar }),
    };
    return { ok: true, value: { kind: 'option', option } };
  }

  const reference = decodeEntityReference({
    ...(id != null && { id }),
    ...(href && { href }),
    ...(name !== undefined && { name }),
  });
  return reference ? { ok: true, value: { kind: 'reference', reference } } : invalidShape;
}

export function decodeUserSelection(raw:unknown):DecodeResult<UserSelection> {
  return decodeSingleEntity<UserFields, IUserAutocompleteItem>(raw, { fieldsOf, halFieldsOf, classify });
}

export function createUserSelectionAdapter():SelectionAdapter<UserSelection> {
  return new SelectionAdapter<UserSelection>(decodeUserSelection, null, entitySelectionToModel, compareByIdentity, trackByIdentity);
}

export function userSelectionToResource(
  value:UserSelection,
  deps:{ halResourceService:HalResourceService; apiV3Service:ApiV3Service },
):HalResource|null {
  if (value === null) {
    return null;
  }

  const pathFor = (id:EntityId):string => deps.apiV3Service.users.id(id).path;

  switch (value.kind) {
    case 'option':
      return deps.halResourceService.createHalResourceOfType('user', value.option.href
        ? { ...value.option }
        : { ...value.option, ...referenceSource({ id: value.option.id }, pathFor) });
    case 'reference':
      return deps.halResourceService.createHalResourceOfType('user', referenceSource(value.reference, pathFor));
  }
}

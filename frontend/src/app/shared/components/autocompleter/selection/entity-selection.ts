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
import { EntityId, EntityReference, isEntityId } from 'core-app/shared/types/entity-reference';
import { DecodeResult, EntitySelection } from './selection-adapter';

export const invalidShape:DecodeResult<never> = { ok: false, issue: { code: 'invalid-shape' } };

export function readProperty(raw:object, key:string):unknown {
  return Reflect.get(raw, key) as unknown;
}

export function halNameOf(resource:HalResource):string|undefined {
  return resource.name || (readProperty(resource.$source, 'name') === '' ? '' : undefined);
}

export function decodeSingleEntity<F, T>(
  raw:unknown,
  decoders:{
    fieldsOf:(raw:object) => F|null;
    halFieldsOf:(resource:HalResource) => F|null;
    classify:(fields:F) => DecodeResult<EntitySelection<T>|null>;
  },
):DecodeResult<EntitySelection<T>|null> {
  if (raw == null) {
    return { ok: true, value: null };
  }
  if (Array.isArray(raw)) {
    return { ok: false, issue: { code: 'wrong-cardinality' } };
  }
  if (isEntityId(raw)) {
    return { ok: true, value: { kind: 'reference', reference: { id: raw } } };
  }
  if (typeof raw !== 'object') {
    return invalidShape;
  }

  const fields = raw instanceof HalResource ? decoders.halFieldsOf(raw) : decoders.fieldsOf(raw);
  return fields ? decoders.classify(fields) : invalidShape;
}

export function identityOf(raw:unknown):{ href?:string; id?:EntityId } {
  if (isEntityId(raw)) {
    return { id: raw };
  }
  if (typeof raw !== 'object' || raw === null) {
    return {};
  }

  const href = readProperty(raw, 'href');
  const id = readProperty(raw, 'id');
  return {
    ...(typeof href === 'string' && href.length > 0 && { href }),
    ...(isEntityId(id) && { id }),
  };
}

export function compareByIdentity(a:unknown, b:unknown):boolean {
  const left = identityOf(a);
  const right = identityOf(b);

  if (left.href !== undefined && right.href !== undefined) {
    return left.href === right.href;
  }
  if (left.id !== undefined && right.id !== undefined) {
    return String(left.id) === String(right.id);
  }
  return false;
}

export function trackByIdentity(raw:unknown):EntityId|undefined {
  const { href, id } = identityOf(raw);
  return href ?? id;
}

export function entitySelectionToModel<T>(value:EntitySelection<T>|null):unknown {
  if (value === null) {
    return null;
  }
  return value.kind === 'option' ? value.option : value.reference;
}

function referenceHref(reference:EntityReference, pathFor:(id:EntityId) => string):string|null {
  if (reference.href) {
    return reference.href;
  }
  return reference.id != null ? pathFor(reference.id) : null;
}

export function referenceSource(reference:EntityReference, pathFor:(id:EntityId) => string) {
  return {
    ...(reference.id != null && { id: reference.id }),
    href: referenceHref(reference, pathFor),
    ...(reference.name !== undefined && { name: reference.name }),
  };
}

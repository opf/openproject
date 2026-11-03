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
import type {
  ILabelAutocompleteItem,
} from 'core-app/shared/components/autocompleter/labels-autocompleter/labels-autocompleter.component';
import { EntityId, decodeEntityReference, isEntityId } from 'core-app/shared/types/entity-reference';
import {
  compareByIdentity,
  halNameOf,
  identityOf,
  invalidShape,
  readProperty,
  referenceSource,
  trackByIdentity,
} from './entity-selection';
import {
  DecodeResult, EntitySelection, SelectionAdapter, decodeAll,
} from './selection-adapter';

export type ExistingLabel = ILabelAutocompleteItem & { id:EntityId };

export interface LabelDraft {
  name:string;
}

export type LabelSelection =
  | EntitySelection<ExistingLabel>
  | { kind:'draft'; draft:LabelDraft };

interface LabelFields {
  id:EntityId|null|undefined;
  name:string|undefined;
  href:string|null|undefined;
}

function fieldsOf(raw:object):LabelFields|null {
  const id = readProperty(raw, 'id');
  const name = readProperty(raw, 'name');
  const href = readProperty(raw, 'href');

  if (!(id == null || isEntityId(id))) { return null; }
  if (!(name === undefined || typeof name === 'string')) { return null; }
  if (!(href == null || (typeof href === 'string' && href.length > 0))) { return null; }

  return { id, name, href };
}

function halFieldsOf(resource:HalResource):LabelFields|null {
  return fieldsOf({
    id: resource.id ?? undefined,
    name: halNameOf(resource),
    href: resource.href,
  });
}

function classify({ id, name, href }:LabelFields):DecodeResult<LabelSelection> {
  if (id == null && !href) {
    const draftName = name?.trim();
    return draftName ? { ok: true, value: { kind: 'draft', draft: { name: draftName } } } : invalidShape;
  }

  if (id != null && name !== undefined && href !== undefined) {
    return { ok: true, value: { kind: 'option', option: { id, name, href } } };
  }

  const reference = decodeEntityReference({
    ...(id != null && { id }),
    ...(href && { href }),
    ...(name !== undefined && { name }),
  });
  return reference ? { ok: true, value: { kind: 'reference', reference } } : invalidShape;
}

function decodeLabel(raw:unknown):DecodeResult<LabelSelection> {
  if (isEntityId(raw)) {
    return { ok: true, value: { kind: 'reference', reference: { id: raw } } };
  }
  if (typeof raw !== 'object' || raw === null || Array.isArray(raw)) {
    return invalidShape;
  }

  const fields = raw instanceof HalResource ? halFieldsOf(raw) : fieldsOf(raw);
  return fields ? classify(fields) : invalidShape;
}

function isEmptyRelationship(raw:unknown):boolean {
  return typeof raw === 'object' && raw !== null && !Array.isArray(raw)
    && Object.keys(raw).length === 1 && readProperty(raw, 'href') === null;
}

export function decodeLabelSelections(raw:unknown, phase:'load'|'change'):DecodeResult<LabelSelection[]> {
  if (raw == null) {
    return { ok: true, value: [] };
  }
  if (Array.isArray(raw)) {
    return decodeAll<LabelSelection>(raw, (entry, index) => {
      const result = decodeLabel(entry);
      return result.ok ? result : { ok: false, issue: { ...result.issue, index } };
    });
  }
  if (phase === 'change') {
    return { ok: false, issue: { code: 'wrong-cardinality' } };
  }
  if (isEmptyRelationship(raw)) {
    return { ok: true, value: [] };
  }

  const single = decodeLabel(raw);
  return single.ok ? { ok: true, value: [single.value] } : single;
}

function nameOfCompleteLabel(raw:unknown):string|undefined {
  if (typeof raw !== 'object' || raw === null) {
    return undefined;
  }

  const name = readProperty(raw, 'name');
  const complete = typeof name === 'string'
    && readProperty(raw, 'id') !== undefined
    && readProperty(raw, 'href') !== undefined;
  return complete ? name : undefined;
}

function hasIdentity(raw:unknown):boolean {
  const { href, id } = identityOf(raw);
  return href !== undefined || id !== undefined;
}

export function compareLabels(a:unknown, b:unknown):boolean {
  const left = nameOfCompleteLabel(a);
  const right = nameOfCompleteLabel(b);
  if (left !== undefined && right !== undefined) {
    return left.toLowerCase() === right.toLowerCase();
  }

  return hasIdentity(a) && hasIdentity(b) && compareByIdentity(a, b);
}

function trackLabel(raw:unknown):EntityId|undefined {
  const identity = trackByIdentity(raw);
  if (identity !== undefined || typeof raw !== 'object' || raw === null) {
    return identity;
  }

  const name = readProperty(raw, 'name');
  return typeof name === 'string' ? name : undefined;
}

function labelSelectionToModel(value:LabelSelection):unknown {
  switch (value.kind) {
    case 'option':
      return value.option;
    case 'reference':
      return value.reference;
    case 'draft':
      return { id: null, href: null, name: value.draft.name };
  }
}

export function labelSelectionsToModel(values:readonly LabelSelection[]):unknown[] {
  return values.map(labelSelectionToModel);
}

export function createLabelSelectionAdapter():SelectionAdapter<LabelSelection[]> {
  return new SelectionAdapter<LabelSelection[]>(
    decodeLabelSelections,
    [],
    labelSelectionsToModel,
    compareLabels,
    trackLabel,
  );
}

export function labelSelectionToResources(
  values:readonly LabelSelection[],
  deps:{ halResourceService:HalResourceService; apiV3Service:ApiV3Service },
):HalResource[] {
  const pathFor = (id:EntityId):string => deps.apiV3Service.labels.id(id).path;

  return values.map((value) => {
    switch (value.kind) {
      case 'option':
        return deps.halResourceService.createHalResourceOfType('Label', value.option.href
          ? { ...value.option }
          : referenceSource({ id: value.option.id, name: value.option.name }, pathFor));
      case 'reference':
        return deps.halResourceService.createHalResourceOfType('Label', referenceSource(value.reference, pathFor));
      case 'draft':
        return deps.halResourceService.createHalResourceOfType('Label', { id: null, href: null, name: value.draft.name });
    }
  });
}

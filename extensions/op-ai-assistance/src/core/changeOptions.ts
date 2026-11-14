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

import type { ChangeKey, ProposalScope } from '../shared/types';

export const TEXT_KEYS = ['subject', 'description', 'comment'] as const;
export const DATE_KEYS = ['start_date', 'due_date'] as const;
export const ASSOCIATION_KEYS = ['status', 'priority', 'assigned_to', 'responsible'] as const;
export const ATTRIBUTE_KEYS:ChangeKey[] = ['subject', 'description', ...ASSOCIATION_KEYS, ...DATE_KEYS];

export type AssociationKey = (typeof ASSOCIATION_KEYS)[number];

export interface Choice {
  href:string;
  name:string;
}

// The current values, with API v3 hrefs for associations.
export type CurrentValues = Partial<Record<ChangeKey, string | null>>;

export interface ChangeOptionsData {
  // The keys that the work package form allows this user to write.
  writable:ChangeKey[];
  choices:Partial<Record<AssociationKey, Choice[]>>;
  current:CurrentValues;
}

const isText = (key:string):boolean => (TEXT_KEYS as readonly string[]).includes(key);
const isDate = (key:string):boolean => (DATE_KEYS as readonly string[]).includes(key);
const isAssociation = (key:string):key is AssociationKey => (ASSOCIATION_KEYS as readonly string[]).includes(key);

export function keysForScope(scope:ProposalScope):ChangeKey[] {
  switch (scope) {
    case 'changes':
      return [...ATTRIBUTE_KEYS, 'comment'];
    case 'comment_only':
      return ['comment'];
    case 'read_only':
      return [];
  }
}

// The values a proposal may set on one work package: the keys of the skill's scope that the
// form allows, with the values valid now. The model gets the names; answers are mapped back
// to hrefs here, so the model never invents ids.
export class ChangeOptions {
  readonly keys:ChangeKey[];

  constructor(scope:ProposalScope, private readonly data:ChangeOptionsData) {
    const writable = new Set<ChangeKey>([...data.writable, 'comment']);
    this.keys = keysForScope(scope).filter((key) => writable.has(key));
  }

  forPrompt():Record<string, string | string[]> {
    return Object.fromEntries(this.keys.map((key):[string, string | string[]] => {
      if (isText(key)) return [key, 'text'];
      if (isDate(key)) return [key, 'ISO date (YYYY-MM-DD)'];
      return [key, this.choices(key).map((choice) => choice.name)];
    }));
  }

  // The value to store for the model's answer, or null when it is not allowed.
  resolve(key:string, answer:unknown):{ key:ChangeKey; value:string; label:string } | null {
    const text = typeof answer === 'string' ? answer.trim() : '';
    const changeKey = this.keys.find((allowed) => allowed === key);
    if (!changeKey || text === '') return null;

    if (isText(changeKey)) {
      const value = changeKey === 'subject' ? text.slice(0, 255) : text;
      return { key: changeKey, value, label: value };
    }
    if (isDate(changeKey)) {
      const value = isoDate(text);
      return value ? { key: changeKey, value, label: value } : null;
    }
    const choice = isAssociation(changeKey)
      ? this.choices(changeKey).find((option) => option.name.toLowerCase() === text.toLowerCase())
      : undefined;
    return choice ? { key: changeKey, value: choice.href, label: choice.name } : null;
  }

  currentValue(key:ChangeKey):string | null {
    if (key === 'comment') return null;
    return this.data.current[key] ?? null;
  }

  private choices(key:ChangeKey):Choice[] {
    return isAssociation(key) ? this.data.choices[key] ?? [] : [];
  }
}

function isoDate(text:string):string | null {
  const match = /^(\d{4})-(\d{2})-(\d{2})$/.exec(text);
  if (!match) return null;
  const date = new Date(`${text}T00:00:00Z`);
  return !Number.isNaN(date.getTime()) && date.toISOString().startsWith(text) ? text : null;
}

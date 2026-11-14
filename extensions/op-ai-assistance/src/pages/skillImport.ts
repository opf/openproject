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

import type { ProposalScope, Skill } from '../shared/types';

const SCOPES:ProposalScope[] = ['changes', 'comment_only', 'read_only'];

const text = (value:unknown, fallback = ''):string => (typeof value === 'string' ? value : fallback);

// Reads an exported skill file. Unknown fields are dropped and missing ones get safe
// defaults: an imported skill proposes nothing unless the file says otherwise.
export function parseSkillImport(json:string):{ instructions?:string; skills:Skill[] } {
  let data:unknown;
  try {
    data = JSON.parse(json);
  } catch {
    throw new Error('The file is not valid JSON.');
  }
  const root = (data ?? {}) as { instructions?:unknown; skills?:unknown };
  if (!Array.isArray(root.skills)) throw new Error('The file has no "skills" list.');

  const skills = (root.skills as unknown[]).map((raw, index):Skill => {
    const skill = (raw ?? {}) as Record<string, unknown>;
    const scope = SCOPES.find((value) => value === skill.scope) ?? 'read_only';
    return {
      id: text(skill.id) || `imported-${index}-${Date.now()}`,
      label: text(skill.label, `Skill ${index + 1}`),
      description: text(skill.description),
      icon: text(skill.icon, '✦').slice(0, 4),
      prompt: text(skill.prompt),
      scope,
      answersAtOnce: skill.answersAtOnce === true,
      useTools: skill.useTools !== false,
    };
  });

  return { ...(typeof root.instructions === 'string' ? { instructions: root.instructions } : {}), skills };
}

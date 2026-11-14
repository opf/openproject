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

import type { ChangeAction, ChangeKey, RawProposal, Severity } from '../shared/types';
import { ATTRIBUTE_KEYS, type ChangeOptions } from './changeOptions';
import { asText } from '../shared/text';

export const SEVERITIES:Severity[] = ['high', 'medium', 'low'];
export const AREAS = ['content', 'status', 'relations', 'tree', 'pull_requests'];
const NONE = 'none';
const MAX_TEXT = 1_000;
const MAX_EVIDENCE = 5;
const MAX_EVIDENCE_TEXT = 500;
const CHANGE_AREAS:Partial<Record<ChangeKey, string>> = {
  subject: 'content',
  description: 'content',
  comment: 'content',
  status: 'status',
};
const FIELD_ORDER:ChangeKey[] = [...ATTRIBUTE_KEYS, 'comment'];

export interface EvaluatedProposal {
  text:string;
  severity:Severity | null;
  area:string | null;
  evidence:string[];
  actions:ChangeAction[];
}

export type Evaluation = { proposal:EvaluatedProposal; reason:null } | { proposal:null; reason:string };

const truncate = (text:string, length:number):string => (text.length > length ? `${text.slice(0, length - 1)}…` : text);

// Turns the model's list of { field, value } into resolved actions. A value that is not
// allowed, or that changes nothing, is dropped.
export function buildActions(options:ChangeOptions, rawChanges:unknown):ChangeAction[] {
  const actions = new Map<ChangeKey, ChangeAction>();
  for (const raw of Array.isArray(rawChanges) ? rawChanges as unknown[] : []) {
    const change = (raw ?? {}) as { field?:unknown; value?:unknown };
    const resolved = options.resolve(asText(change.field), change.value);
    if (!resolved || actions.has(resolved.key) || resolved.value === options.currentValue(resolved.key)) continue;
    actions.set(resolved.key, resolved);
  }
  return [...actions.values()];
}

// The one answer format of every turn: text, and proposals. A proposal is a finding (a problem,
// with a severity, an area and evidence) or a plain change that the user asked for.
export class AnswerFormat {
  constructor(private readonly options:ChangeOptions) {}

  schema():Record<string, unknown> {
    return {
      type: 'object',
      additionalProperties: false,
      required: ['answer', 'proposals'],
      properties: {
        answer: { type: 'string' },
        proposals: { type: 'array', items: this.proposalSchema() },
      },
    };
  }

  evaluate(raw:RawProposal):Evaluation {
    const text = truncate(asText(raw.text).trim(), MAX_TEXT);
    const actions = buildActions(this.options, raw.changes);
    const severity = SEVERITIES.find((value) => value === raw.severity);

    if (severity) return this.finding(raw, severity, text, actions);
    if (actions.length > 0) return { proposal: { text, severity: null, area: null, evidence: [], actions }, reason: null };
    return { proposal: null, reason: 'no valid change' };
  }

  // A fixed order within a severity, so that runs with the same proposals list them the same
  // way: by the first changed field, then by area, then in the model's order.
  sort(proposals:EvaluatedProposal[]):EvaluatedProposal[] {
    return proposals
      .map((proposal, index) => ({ proposal, key: [...sortKey(proposal), index] }))
      .sort((a, b) => compareKeys(a.key, b.key))
      .map(({ proposal }) => proposal);
  }

  private proposalSchema():Record<string, unknown> {
    return {
      type: 'object',
      additionalProperties: false,
      required: ['text', 'severity', 'area', 'evidence', 'changes'],
      properties: {
        text: { type: 'string' },
        severity: { type: 'string', enum: [...SEVERITIES, NONE] },
        area: { type: 'string', enum: [...AREAS, NONE] },
        evidence: { type: 'array', items: { type: 'string' } },
        changes: {
          type: 'array',
          items: {
            type: 'object',
            additionalProperties: false,
            required: ['field', 'value'],
            properties: {
              field: { type: 'string', enum: this.options.keys.length > 0 ? this.options.keys : [NONE] },
              value: { type: 'string' },
            },
          },
        },
      },
    };
  }

  private finding(raw:RawProposal, severity:Severity, text:string, actions:ChangeAction[]):Evaluation {
    const evidence = (Array.isArray(raw.evidence) ? raw.evidence as unknown[] : [])
      .map((item) => asText(item).trim())
      .filter((item) => item.length > 0);
    if (evidence.length === 0) return { proposal: null, reason: 'no evidence' };
    if (text === '') return { proposal: null, reason: 'no text' };

    return {
      proposal: {
        text,
        severity,
        area: areaFor(raw.area, actions),
        evidence: evidence.slice(0, MAX_EVIDENCE).map((item) => truncate(item, MAX_EVIDENCE_TEXT)),
        actions,
      },
      reason: null,
    };
  }
}

// The changed fields name the area. Models label it inconsistently: some use "none" for
// findings, or one area for all of them.
function areaFor(area:unknown, actions:ChangeAction[]):string | null {
  const fromChanges = actions.map((action) => CHANGE_AREAS[action.key]).find((value) => value !== undefined);
  if (fromChanges) return fromChanges;
  return typeof area === 'string' && AREAS.includes(area) ? area : null;
}

function sortKey(proposal:EvaluatedProposal):number[] {
  const fieldIndexes = proposal.actions.map((action) => FIELD_ORDER.indexOf(action.key)).filter((index) => index >= 0);
  const areaIndex = proposal.area ? AREAS.indexOf(proposal.area) : -1;
  return [
    fieldIndexes.length > 0 ? Math.min(...fieldIndexes) : FIELD_ORDER.length,
    areaIndex >= 0 ? areaIndex : AREAS.length,
  ];
}

function compareKeys(a:number[], b:number[]):number {
  for (let index = 0; index < a.length; index += 1) {
    const difference = (a[index] ?? 0) - (b[index] ?? 0);
    if (difference !== 0) return difference;
  }
  return 0;
}

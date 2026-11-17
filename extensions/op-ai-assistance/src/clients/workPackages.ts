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

import type { ChangeOptionsData, Choice } from '../core/changeOptions';
import { lostReferences } from '../core/contentGuard';
import type { ChangeKey, Proposal } from '../shared/types';
import { type Hal, OpenProjectClient, OpenProjectError } from './openproject';
import { asText } from '../shared/text';

const MAX_COMMENTS = 30;
const MAX_TEXT = 4_000;
const MAX_CHILDREN = 200;

const truncate = (text:string, length:number):string => (text.length > length ? `${text.slice(0, length - 1)}…` : text);

const link = (resource:Hal, name:string):{ href:string | null; title:string | null } => {
  const value = resource._links?.[name];
  return { href: value?.href ?? null, title: value?.title ?? null };
};

const elements = (collection:Hal):Hal[] => (collection._embedded?.elements ?? []) as Hal[];

const filterQuery = (filters:unknown[], extra = ''):string => `filters=${encodeURIComponent(JSON.stringify(filters))}${extra}`;

export interface LoadedWorkPackage {
  id:string;
  subject:string;
  description:string;
  lockVersion:number;
  context:Record<string, unknown>;
  optionsData:ChangeOptionsData;
}

interface StatusInfo {
  closed:boolean;
  isDefault:boolean;
}

async function statusMap(op:OpenProjectClient):Promise<Map<string, StatusInfo>> {
  const statuses = elements(await op.get('/api/v3/statuses'));
  return new Map(statuses.map((status) => [
    link(status, 'self').href ?? '',
    { closed: status.isClosed === true, isDefault: status.isDefault === true },
  ]));
}

function choicesFrom(field:Hal | undefined):Choice[] {
  const embedded = (field?._embedded?.allowedValues ?? []) as Hal[];
  return embedded.map((value) => ({ href: link(value, 'self').href ?? '', name: asText(value.name) }))
    .filter((choice) => choice.href !== '');
}

async function principalChoices(op:OpenProjectClient, field:Hal | undefined):Promise<Choice[]> {
  const href = (field?._links?.allowedValues as { href?:string } | undefined)?.href;
  if (!href) return choicesFrom(field);
  const separator = href.includes('?') ? '&' : '?';
  return elements(await op.get(`${href}${separator}pageSize=100`))
    .map((principal) => ({ href: link(principal, 'self').href ?? '', name: asText(principal.name) }))
    .filter((choice) => choice.href !== '');
}

type FieldKey = Exclude<ChangeKey, 'comment'>;

// The API v3 name of each field that a proposal can change, and how a PATCH sets it.
const FIELDS:Record<FieldKey, { api:string; kind:'link' | 'formattable' | 'value' }> = {
  subject: { api: 'subject', kind: 'value' },
  description: { api: 'description', kind: 'formattable' },
  status: { api: 'status', kind: 'link' },
  priority: { api: 'priority', kind: 'link' },
  assigned_to: { api: 'assignee', kind: 'link' },
  responsible: { api: 'responsible', kind: 'link' },
  start_date: { api: 'startDate', kind: 'value' },
  due_date: { api: 'dueDate', kind: 'value' },
};

// A user who may not edit the work package gets no form (403): then only a comment can be
// proposed, and a read-only skill still works.
async function formSchema(op:OpenProjectClient, workPackage:Hal):Promise<Record<string, Hal | undefined>> {
  try {
    const form = await op.post(`/api/v3/work_packages/${String(workPackage.id)}/form`, { lockVersion: workPackage.lockVersion });
    return (form._embedded?.schema ?? {}) as Record<string, Hal | undefined>;
  } catch (error) {
    if (error instanceof OpenProjectError) return {};
    throw error;
  }
}

async function changeOptionsData(op:OpenProjectClient, workPackage:Hal):Promise<ChangeOptionsData> {
  const schema = await formSchema(op, workPackage);
  const writable = (Object.entries(FIELDS) as [FieldKey, (typeof FIELDS)[FieldKey]][])
    .filter(([, field]) => schema[field.api]?.writable === true)
    .map(([key]) => key);

  const [assignees, responsibles] = await Promise.all([
    writable.includes('assigned_to') ? principalChoices(op, schema.assignee) : Promise.resolve([]),
    writable.includes('responsible') ? principalChoices(op, schema.responsible) : Promise.resolve([]),
  ]);

  return {
    writable,
    choices: {
      status: choicesFrom(schema.status),
      priority: choicesFrom(schema.priority),
      assigned_to: assignees,
      responsible: responsibles,
    },
    current: {
      subject: asText(workPackage.subject),
      description: descriptionOf(workPackage),
      status: link(workPackage, 'status').href,
      priority: link(workPackage, 'priority').href,
      assigned_to: link(workPackage, 'assignee').href,
      responsible: link(workPackage, 'responsible').href,
      start_date: (workPackage.startDate as string | null | undefined) ?? null,
      due_date: (workPackage.dueDate as string | null | undefined) ?? null,
    },
  };
}

function descriptionOf(workPackage:Hal):string {
  return String((workPackage.description as { raw?:string } | undefined)?.raw ?? '');
}

async function comments(op:OpenProjectClient, workPackage:Hal):Promise<Record<string, unknown>[]> {
  const href = link(workPackage, 'activities').href ?? `/api/v3/work_packages/${String(workPackage.id)}/activities`;
  return elements(await op.get(href))
    .filter((activity) => ((activity.comment as { raw?:string } | undefined)?.raw ?? '').trim() !== '')
    .slice(-MAX_COMMENTS)
    .map((activity) => ({
      author: link(activity, 'user').title,
      at: activity.createdAt,
      internal: activity.internal === true,
      text: truncate((activity.comment as { raw:string }).raw, MAX_TEXT),
    }));
}

async function children(op:OpenProjectClient, id:string, statuses:Map<string, StatusInfo>):Promise<Record<string, unknown>[]> {
  const query = filterQuery([{ parent: { operator: '=', values: [id] } }], `&pageSize=${MAX_CHILDREN}`);
  return elements(await op.get(`/api/v3/work_packages?${query}`)).map((child) => ({
    id: child.id,
    subject: child.subject,
    status: link(child, 'status').title,
    closed: statuses.get(link(child, 'status').href ?? '')?.closed ?? null,
    updated_at: child.updatedAt,
  }));
}

async function relations(op:OpenProjectClient, id:string):Promise<Record<string, unknown>[]> {
  const query = filterQuery([{ involved: { operator: '=', values: [id] } }], '&pageSize=100');
  return elements(await op.get(`/api/v3/relations?${query}`)).map((relation) => {
    const from = link(relation, 'from');
    const outgoing = from.href?.endsWith(`/work_packages/${id}`) ?? false;
    const other = outgoing ? link(relation, 'to') : from;
    return {
      relation: outgoing ? relation.type : relation.reverseType,
      id: other.href?.split('/').pop() ?? null,
      subject: other.title,
    };
  });
}

// What the model gets to know about a work package: only what the user can see through
// API v3, with the values that a proposal may set.
export async function loadWorkPackage(op:OpenProjectClient, id:string):Promise<LoadedWorkPackage> {
  const workPackage = await op.get(`/api/v3/work_packages/${encodeURIComponent(id)}`);
  const numericId = String(workPackage.id);
  const loadingStatuses = statusMap(op);
  const [optionsData, commentList, childList, relationList, statuses] = await Promise.all([
    changeOptionsData(op, workPackage),
    comments(op, workPackage),
    loadingStatuses.then((map) => children(op, numericId, map)),
    relations(op, numericId),
    loadingStatuses,
  ]);
  const status = statuses.get(link(workPackage, 'status').href ?? '');
  const lastComment = commentList.at(-1)?.at as string | undefined;
  const updatedAt = workPackage.updatedAt as string | undefined;

  return {
    id: numericId,
    subject: asText(workPackage.subject),
    description: descriptionOf(workPackage),
    lockVersion: Number(workPackage.lockVersion ?? 0),
    optionsData,
    context: {
      project: { name: link(workPackage, 'project').title },
      work_package: {
        id: numericId,
        type: link(workPackage, 'type').title,
        subject: workPackage.subject,
        description: truncate(descriptionOf(workPackage), MAX_TEXT * 3),
        status: link(workPackage, 'status').title,
        default_status: status?.isDefault ?? false,
        closed: status?.closed ?? false,
        priority: link(workPackage, 'priority').title,
        assignee: link(workPackage, 'assignee').title,
        responsible: link(workPackage, 'responsible').title,
        start_date: workPackage.startDate ?? null,
        due_date: workPackage.dueDate ?? null,
        last_activity_at: [lastComment, updatedAt].filter(Boolean).sort().at(-1) ?? null,
      },
      children: childList,
      relations: relationList,
      comments: commentList,
    },
  };
}

export class ApplyError extends Error {}

function checkDescription(current:string, proposed:string, base:string | undefined):void {
  if (base !== undefined && current !== base) {
    throw new ApplyError('The description changed after this proposal was made. Ask again to get a current proposal.');
  }
  if (lostReferences(current, proposed).length > 0) {
    throw new ApplyError('This proposal removes images, mentions or macros from the description. Edit the description yourself.');
  }
}

// Applies one proposal as the user: the attribute changes in one PATCH with the current
// lockVersion, then the comment. A description that has changed since the proposal, or a
// proposed description that drops images, mentions or macros, is not applied.
export async function applyProposal(op:OpenProjectClient, id:string, proposal:Proposal):Promise<void> {
  const workPackage = await op.get(`/api/v3/work_packages/${encodeURIComponent(id)}`);
  const body:Record<string, unknown> = { lockVersion: workPackage.lockVersion };
  const links:Record<string, { href:string }> = {};
  let comment:string | null = null;

  for (const action of proposal.actions) {
    if (action.key === 'comment') {
      comment = action.value;
      continue;
    }
    const field = FIELDS[action.key];
    if (field.kind === 'link') {
      links[field.api] = { href: action.value };
    } else if (field.kind === 'formattable') {
      checkDescription(descriptionOf(workPackage), action.value, proposal.baseDescription);
      body[field.api] = { raw: action.value };
    } else {
      body[field.api] = action.value;
    }
  }
  if (Object.keys(links).length > 0) body._links = links;

  try {
    if (Object.keys(body).length > 1) {
      await op.patch(`/api/v3/work_packages/${encodeURIComponent(id)}`, body);
    }
    if (comment) {
      const href = link(workPackage, 'addComment').href ?? `/api/v3/work_packages/${encodeURIComponent(id)}/activities`;
      await op.post(href, { comment: { raw: comment } });
    }
  } catch (error) {
    if (error instanceof OpenProjectError && error.status === 409) {
      throw new ApplyError('The work package changed after this proposal was made. Ask again to get a current proposal.');
    }
    throw error;
  }
}

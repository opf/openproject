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

import type { Settings, Skill } from './types';

export const DEFAULT_MODELS = {
  anthropic: 'claude-opus-5-5',
  openai: 'gpt-4.1',
} as const;

export const DEFAULT_BASE_URLS = {
  anthropic: 'https://api.anthropic.com',
  openai: 'https://api.openai.com/v1',
} as const;

export const START_REQUEST = 'Apply your instructions to this work package, as it is now.';

const REFRESH_PROMPT = `You check one work package of a project management tool for places where it is
inconsistent with itself: its subject, its description, its comments, its status,
its relations and its children. Answer with findings.

Look for:
- comments that changed the scope, a decision or a deadline, which the description
  does not show yet;
- comments that changed the assignee, the accountable person or the priority;
- a subject that no longer names what the work package is about;
- a description that promises work which the children do not cover, or the opposite;
- a status that the comments contradict;
- a closed work package with open children, or an open one whose children are all closed;
- a closed work package that follows or is blocked by an open one;
- an open work package that duplicates a closed one;
- open work, here or in a child, with no activity for 60 days.

Report only what you can show with evidence: quote the comment, or name the field.
Report nothing rather than a guess.`;

const CHAT_PROMPT = `Answer the user's questions about this work package: its subject, description, status,
dates, comments, relations and children, or about anything else the user can see in OpenProject.
Keep the answers short.`;

export const DEFAULT_SKILLS:Skill[] = [
  {
    id: 'refresh',
    label: 'Refresh work package',
    description: 'Finds where this work package no longer matches its comments, children and relations, and proposes updates.',
    icon: '↻',
    prompt: REFRESH_PROMPT,
    scope: 'changes',
    answersAtOnce: true,
    useTools: true,
  },
  {
    id: 'chat',
    label: 'Chat',
    description: 'Ask questions. Only you see the chat.',
    icon: '💬',
    prompt: CHAT_PROMPT,
    scope: 'comment_only',
    answersAtOnce: false,
    useTools: true,
  },
];

export const DEFAULT_SETTINGS:Settings = {
  instanceUrl: '',
  authMode: 'session',
  apiToken: '',
  provider: 'anthropic',
  llmKey: '',
  llmBaseUrl: '',
  model: DEFAULT_MODELS.anthropic,
  instructions: 'You help the users of OpenProject, a project management tool. Use the context you get and the tools. '
    + 'When they do not answer a question, say so.',
  skills: DEFAULT_SKILLS,
};

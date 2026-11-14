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

import { AnswerFormat } from '../core/answerFormat';
import { ChangeOptions } from '../core/changeOptions';
import type { LlmMessage, ToolSet } from '../core/llmTypes';
import { systemPrompt } from '../core/outputRules';
import { reply } from '../core/reply';
import { START_REQUEST } from '../shared/defaults';
import { newId } from '../shared/storage';
import type { Chat, ChatMessage, RunEvent, Settings, Skill } from '../shared/types';
import { llmClient } from './llm';
import { McpClient, McpUnavailable, type OpenProjectClient } from './openproject';
import { loadWorkPackage } from './workPackages';

const MAX_TURNS = 20;
const EMPTY_ANSWER = '(The model gave no answer.)';

function turnText(message:ChatMessage):string {
  if (message.role === 'start') return START_REQUEST;
  if (message.role === 'user' || message.proposals.length === 0) return message.content;
  const lines = message.proposals.map((proposal) => `- ${proposal.text || proposal.actions.map((action) => action.key).join(', ')} (${proposal.state})`);
  return [message.content, `Proposals:\n${lines.join('\n')}`].filter(Boolean).join('\n\n');
}

// The finished turns before the question, oldest first. An earlier answer comes with its
// proposals, so that the model knows what it proposed.
function history(chat:Chat):LlmMessage[] {
  return chat.messages
    .slice(0, -1)
    .filter((message) => message.status === 'done')
    .slice(-MAX_TURNS)
    .map((message) => ({ role: message.role === 'assistant' ? 'assistant' : 'user', content: turnText(message) }));
}

interface ToolLookup {
  tools:ToolSet | null;
  note:string | null;
}

async function lookUpTools(op:OpenProjectClient):Promise<ToolLookup> {
  try {
    const tools = await new McpClient(op).readOnlyTools();
    return tools.definitions.length > 0
      ? { tools, note: null }
      : { tools: null, note: 'The MCP server offers no read-only tools.' };
  } catch (error) {
    if (!(error instanceof McpUnavailable)) throw error;
    return { tools: null, note: error.message };
  }
}

// One lookup per dialog: the tool list does not change between the turns of a chat. A failed
// lookup is not kept, so the next turn tries again.
const toolLookups = new WeakMap<OpenProjectClient, Promise<ToolLookup>>();

async function readOnlyTools(op:OpenProjectClient, record:(event:RunEvent) => void):Promise<ToolSet | null> {
  let lookup = toolLookups.get(op);
  if (!lookup) {
    lookup = lookUpTools(op);
    toolLookups.set(op, lookup);
    lookup.catch(() => toolLookups.delete(op));
  }
  const { tools, note } = await lookup;
  if (note) record({ type: 'note', text: `${note} The answer uses only the work package.` });
  return tools;
}

export interface AnswerInput {
  settings:Settings;
  skill:Skill;
  // The chat, ending with the question (or the start) to answer.
  chat:Chat;
  op:OpenProjectClient;
  locale:string;
}

// Answers the latest message of a chat, as the signed-in user. Any failure gives a failed
// answer with its events, so the dialog never waits forever.
export async function answer({ settings, skill, chat, op, locale }:AnswerInput):Promise<ChatMessage> {
  const events:RunEvent[] = [];
  const record = (event:RunEvent):void => {
    events.push(event);
  };
  const message = (content:string, status:ChatMessage['status'], proposals:ChatMessage['proposals'] = []):ChatMessage => ({
    id: newId(),
    role: 'assistant',
    content,
    createdAt: new Date().toISOString(),
    status,
    proposals,
    events,
  });

  try {
    const question = chat.messages.at(-1);
    if (!question) throw new Error('There is no question.');

    const workPackage = await loadWorkPackage(op, chat.workPackageId);
    const options = new ChangeOptions(skill.scope, workPackage.optionsData);
    const tools = skill.useTools ? await readOnlyTools(op, record) : null;

    const result = await reply({
      llm: llmClient(settings),
      system: systemPrompt(settings.instructions, skill, { locale, tools: tools !== null }),
      context: { ...workPackage.context, change_options: options.forPrompt() },
      history: history(chat),
      question: turnText(question),
      answerFormat: new AnswerFormat(options),
      tools,
      record,
    });

    return message(result.answer || EMPTY_ANSWER, 'done', result.proposals.map((proposal) => ({
      ...proposal,
      id: newId(),
      state: 'open',
      ...(proposal.actions.some((action) => action.key === 'description') ? { baseDescription: workPackage.description } : {}),
    })));
  } catch (error) {
    record({ type: 'failure', error: error instanceof Error ? error.message : String(error) });
    return message('', 'failed');
  }
}

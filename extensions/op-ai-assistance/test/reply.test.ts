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

import { describe, expect, it } from 'vitest';
import { AnswerFormat } from '../src/core/answerFormat';
import type { LlmClient, LlmRequest, LlmTurn, ToolSet } from '../src/core/llmTypes';
import { reply, SUBMIT_TOOL } from '../src/core/reply';
import type { RunEvent } from '../src/shared/types';
import { changeOptions } from './helpers';

class ScriptedLlm implements LlmClient {
  readonly model = 'test-model';
  readonly requests:LlmRequest[] = [];

  constructor(private readonly turns:LlmTurn[]) {}

  complete(request:LlmRequest):Promise<LlmTurn> {
    this.requests.push(structuredClone(request));
    const turn = this.turns.shift();
    return turn ? Promise.resolve(turn) : Promise.reject(new Error('no more turns'));
  }
}

const submit = (args:Record<string, unknown>):LlmTurn => ({ text: '', toolCalls: [{ id: 's', name: SUBMIT_TOOL, args }] });

const tools:ToolSet = {
  definitions: [{ name: 'search_users', description: 'Search users', inputSchema: { type: 'object' } }],
  call: (_name, args) => Promise.resolve(JSON.stringify({ items: [{ id: 5, query: args.search_term }] })),
};

function run(llm:LlmClient, toolSet:ToolSet | null = tools) {
  const events:RunEvent[] = [];
  const result = reply({
    llm,
    system: 'You help.',
    context: { work_package: { id: 1 } },
    history: [],
    question: 'Who works on this?',
    answerFormat: new AnswerFormat(changeOptions()),
    tools: toolSet,
    record: (event) => events.push(event),
  });
  return { events, result };
}

describe('reply', () => {
  it('runs the tool loop and returns the submitted answer with its proposals', async () => {
    const llm = new ScriptedLlm([
      { text: 'Looking up users.', toolCalls: [{ id: 't1', name: 'search_users', args: { search_term: 'Jane' } }] },
      submit({
        answer: 'Jane works on it.',
        proposals: [{ text: 'Assign Jane', severity: 'none', area: 'none', evidence: [], changes: [{ field: 'assigned_to', value: 'Jane Doe' }] }],
      }),
    ]);
    const { events, result } = run(llm);

    await expect(result).resolves.toMatchObject({
      answer: 'Jane works on it.',
      proposals: [{ actions: [{ key: 'assigned_to', value: '/api/v3/users/5' }] }],
    });
    expect(events.map((event) => event.type)).toEqual(['request', 'thought', 'tool_call', 'answer', 'stored']);
    expect(llm.requests[0]?.system).toContain('Context (JSON):\n{"work_package":{"id":1}}');
    expect(llm.requests[1]?.messages.at(-1)).toMatchObject({ role: 'tool', toolCallId: 't1', name: 'search_users' });
  });

  it('forces the submit tool once when the model answers with plain text', async () => {
    const llm = new ScriptedLlm([{ text: 'Plain text.', toolCalls: [] }, submit({ answer: 'Done.', proposals: [] })]);
    const { result } = run(llm);

    await expect(result).resolves.toEqual({ answer: 'Done.', proposals: [] });
    expect(llm.requests[1]?.forceTool).toBe(SUBMIT_TOOL);
  });

  it('asks again once when every proposal is dropped', async () => {
    const llm = new ScriptedLlm([
      submit({ answer: 'One finding.', proposals: [{ text: 'Guess', severity: 'high', area: 'status', evidence: [], changes: [] }] }),
      submit({ answer: 'One finding.', proposals: [{ text: 'Shown', severity: 'high', area: 'status', evidence: ['Comment'], changes: [] }] }),
    ]);
    const { result } = run(llm, null);

    await expect(result).resolves.toMatchObject({ proposals: [{ text: 'Shown' }] });
    expect(llm.requests[1]?.messages.at(-1)).toMatchObject({ role: 'user', content: expect.stringContaining('1: no evidence') as string });
  });

  it('offers only the submit tool when there are no tools', async () => {
    const llm = new ScriptedLlm([submit({ answer: 'Hi', proposals: [] })]);
    await run(llm, null).result;
    expect(llm.requests[0]?.tools.map((tool) => tool.name)).toEqual([SUBMIT_TOOL]);
  });
});

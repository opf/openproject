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

import type { RawAnswer, RawProposal, RunEvent } from '../shared/types';
import type { AnswerFormat, EvaluatedProposal } from './answerFormat';
import type { LlmClient, LlmMessage, ToolDefinition, ToolSet } from './llmTypes';
import { HARD_LIMIT, ToolCalls } from './toolCalls';

export const SUBMIT_TOOL = 'submit_answer';
const MAX_PROPOSALS = 15;
// Tool turns, plus the turns that answer or that are told to answer.
const MAX_MODEL_TURNS = HARD_LIMIT + 3;
const ANSWER_NOW = `Give your final answer now by calling ${SUBMIT_TOOL}.`;
const RETRY = 'None of your proposals can be stored. The reason for each proposal: %s. Answer again in the same '
  + 'format, and fix this. A finding needs evidence and a text; a plain proposal needs a valid change.';

export interface ReplyInput {
  llm:LlmClient;
  system:string;
  context:Record<string, unknown>;
  // Earlier turns, oldest first, as plain text.
  history:LlmMessage[];
  question:string;
  answerFormat:AnswerFormat;
  tools:ToolSet | null;
  record:(event:RunEvent) => void;
}

export interface ReplyResult {
  answer:string;
  proposals:EvaluatedProposal[];
}

class Asker {
  private readonly toolCalls:ToolCalls;
  private readonly definitions:ToolDefinition[];
  private readonly system:string;

  constructor(private readonly input:ReplyInput) {
    this.toolCalls = new ToolCalls((event) => input.record(event));
    this.system = `${input.system}\n\nContext (JSON):\n${JSON.stringify(input.context)}`;
    this.definitions = [
      ...(input.tools?.definitions ?? []),
      { name: SUBMIT_TOOL, description: 'Give the final answer of this turn.', inputSchema: input.answerFormat.schema(), strict: true },
    ];
  }

  async ask(correction:LlmMessage[] = []):Promise<RawAnswer> {
    const { llm, question, record } = this.input;
    const messages:LlmMessage[] = [...this.input.history, { role: 'user', content: question }, ...correction];
    record({ type: 'request', model: llm.model, system: this.system, message: question, tools: this.definitions.length - 1 });

    const started = performance.now();
    let forced = false;
    for (let turnIndex = 0; turnIndex < MAX_MODEL_TURNS; turnIndex += 1) {
      const turn = await llm.complete({
        system: this.system,
        messages,
        tools: this.definitions,
        forceTool: forced ? SUBMIT_TOOL : undefined,
      });

      const submitted = turn.toolCalls.find((call) => call.name === SUBMIT_TOOL);
      if (submitted) return this.finish(submitted.args, started);

      if (turn.toolCalls.length === 0) {
        if (forced) return this.finish({ answer: turn.text, proposals: [] }, started);
        forced = true;
        messages.push({ role: 'assistant', content: turn.text, raw: turn.raw }, { role: 'user', content: ANSWER_NOW });
        continue;
      }

      if (turn.text.trim()) record({ type: 'thought', text: turn.text.trim() });
      messages.push({ role: 'assistant', content: turn.text, toolCalls: turn.toolCalls, raw: turn.raw });
      for (const call of turn.toolCalls) {
        const content = await this.toolCalls.run(call.name, call.args, () => this.callTool(call.name, call.args));
        messages.push({ role: 'tool', toolCallId: call.id, name: call.name, content });
      }
    }
    throw new Error('The model did not answer.');
  }

  private finish(answer:RawAnswer, started:number):RawAnswer {
    this.input.record({
      type: 'answer',
      seconds: Math.round((performance.now() - started) / 100) / 10,
      toolCalls: this.toolCalls.count,
      content: JSON.stringify(answer, null, 2),
    });
    return answer;
  }

  private callTool(name:string, args:Record<string, unknown>):Promise<string> {
    if (!this.input.tools) return Promise.reject(new Error(`Unknown tool ${name}`));
    return this.input.tools.call(name, args);
  }
}

function rawProposals(answer:RawAnswer):RawProposal[] {
  return (Array.isArray(answer.proposals) ? answer.proposals as RawProposal[] : []).slice(0, MAX_PROPOSALS);
}

// Answers one question: the model gets the system prompt, the context, the earlier turns and
// the question, and answers with text and 0..n proposals. When the answer has proposals and
// none of them qualifies, the model is asked once more with the reasons.
export async function reply(input:ReplyInput):Promise<ReplyResult> {
  const asker = new Asker(input);
  let answer = await asker.ask();

  const firstResults = rawProposals(answer).map((raw) => input.answerFormat.evaluate(raw));
  if (firstResults.length > 0 && firstResults.every((result) => result.proposal === null)) {
    const reasons = firstResults.map((result, index) => `${index + 1}: ${result.reason}`).join(', ');
    answer = await asker.ask([
      { role: 'assistant', content: JSON.stringify(answer) },
      { role: 'user', content: RETRY.replace('%s', reasons) },
    ]);
  }

  const raws = rawProposals(answer);
  const results = raws.map((raw) => input.answerFormat.evaluate(raw));
  const kept = results.flatMap((result) => (result.proposal ? [result.proposal] : []));
  if (raws.length > 0) {
    input.record({
      type: 'stored',
      findings: raws.length,
      stored: kept.length,
      dropped: results.flatMap((result, index) => (result.proposal ? [] : [{ reason: result.reason, proposal: raws[index] }])),
    });
  }

  return {
    answer: typeof answer.answer === 'string' ? answer.answer.trim() : '',
    proposals: input.answerFormat.sort(kept),
  };
}

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

import type { LlmClient, LlmMessage, LlmRequest, LlmTurn, ToolCall } from '../core/llmTypes';
import { DEFAULT_BASE_URLS } from '../shared/defaults';
import type { Settings } from '../shared/types';

const MAX_TOKENS = 16_000;

export class LlmError extends Error {
  constructor(message:string, readonly status?:number) {
    super(message);
  }
}

async function postJson(url:string, headers:Record<string, string>, body:unknown):Promise<Record<string, unknown>> {
  const response = await fetch(url, {
    method: 'POST',
    headers: { 'content-type': 'application/json', ...headers },
    body: JSON.stringify(body),
  });
  const text = await response.text();
  if (!response.ok) {
    throw new LlmError(`The LLM server answered ${response.status}: ${text.slice(0, 500)}`, response.status);
  }
  return JSON.parse(text) as Record<string, unknown>;
}

interface AnthropicBlock {
  type:string;
  text?:string;
  id?:string;
  name?:string;
  input?:Record<string, unknown>;
}

// Messages API over plain fetch. Current models think adaptively and reject sampling
// parameters and a forced tool_choice, so the request sends neither: the prompt steers the
// model to the submit tool. Assistant turns go back with their raw content, because a tool
// loop must return the thinking blocks unchanged.
export class AnthropicClient implements LlmClient {
  constructor(
    readonly model:string,
    private readonly apiKey:string,
    private readonly baseUrl:string = DEFAULT_BASE_URLS.anthropic,
  ) {}

  async complete(request:LlmRequest):Promise<LlmTurn> {
    const body = await postJson(`${this.baseUrl.replace(/\/$/, '')}/v1/messages`, {
      'x-api-key': this.apiKey,
      'anthropic-version': '2023-06-01',
      'anthropic-beta': 'server-side-fallback-2026-07-01',
      'anthropic-dangerous-direct-browser-access': 'true',
    }, {
      model: this.model,
      max_tokens: MAX_TOKENS,
      system: request.system,
      fallbacks: 'default',
      tools: request.tools.map((tool) => ({
        name: tool.name,
        description: tool.description,
        input_schema: tool.inputSchema,
        ...(tool.strict ? { strict: true } : {}),
      })),
      tool_choice: { type: 'auto' },
      messages: anthropicMessages(request.messages),
    });

    if (body.stop_reason === 'refusal') {
      const details = body.stop_details as { category?:string; explanation?:string } | null;
      throw new LlmError(`The model declined to answer${details?.category ? ` (${details.category})` : ''}.`);
    }

    const content = (body.content ?? []) as AnthropicBlock[];
    return {
      text: content.filter((block) => block.type === 'text').map((block) => block.text ?? '').join('\n'),
      toolCalls: content
        .filter((block) => block.type === 'tool_use')
        .map((block) => ({ id: block.id ?? '', name: block.name ?? '', args: block.input ?? {} })),
      raw: content,
    };
  }
}

function anthropicMessages(messages:LlmMessage[]):unknown[] {
  const result:{ role:'user' | 'assistant'; content:unknown }[] = [];
  for (const message of messages) {
    if (message.role === 'tool') {
      const block = { type: 'tool_result', tool_use_id: message.toolCallId, content: message.content };
      const last = result.at(-1);
      if (last?.role === 'user' && Array.isArray(last.content)) {
        (last.content as unknown[]).push(block);
      } else {
        result.push({ role: 'user', content: [block] });
      }
    } else if (message.role === 'assistant') {
      result.push({ role: 'assistant', content: message.raw ?? assistantBlocks(message.content, message.toolCalls ?? []) });
    } else {
      result.push({ role: 'user', content: message.content });
    }
  }
  return result;
}

function assistantBlocks(text:string, toolCalls:ToolCall[]):unknown[] {
  return [
    ...(text.trim() ? [{ type: 'text', text }] : [{ type: 'text', text: '…' }]),
    ...toolCalls.map((call) => ({ type: 'tool_use', id: call.id, name: call.name, input: call.args })),
  ];
}

interface OpenAiToolCall {
  id:string;
  function:{ name:string; arguments:string };
}

// Chat Completions, for OpenAI and compatible servers. Reasoning models accept only
// max_completion_tokens and the default temperature, so the request sends no temperature.
export class OpenAiClient implements LlmClient {
  constructor(
    readonly model:string,
    private readonly apiKey:string,
    private readonly baseUrl:string = DEFAULT_BASE_URLS.openai,
  ) {}

  async complete(request:LlmRequest):Promise<LlmTurn> {
    const body = await postJson(`${this.baseUrl.replace(/\/$/, '')}/chat/completions`, {
      authorization: `Bearer ${this.apiKey}`,
    }, {
      model: this.model,
      max_completion_tokens: MAX_TOKENS,
      tools: request.tools.map((tool) => ({
        type: 'function',
        function: { name: tool.name, description: tool.description, parameters: tool.inputSchema },
      })),
      tool_choice: request.forceTool ? { type: 'function', function: { name: request.forceTool } } : 'auto',
      messages: [{ role: 'system', content: request.system }, ...openAiMessages(request.messages)],
    });

    const choice = (body.choices as { message?:{ content?:string | null; tool_calls?:OpenAiToolCall[] } }[] | undefined)?.[0];
    const message = choice?.message ?? {};
    return {
      text: message.content ?? '',
      toolCalls: (message.tool_calls ?? []).map((call) => ({
        id: call.id,
        name: call.function.name,
        args: parseArguments(call.function.arguments),
      })),
    };
  }
}

function openAiMessages(messages:LlmMessage[]):unknown[] {
  return messages.map((message) => {
    if (message.role === 'tool') return { role: 'tool', tool_call_id: message.toolCallId, content: message.content };
    if (message.role === 'assistant') {
      const toolCalls = (message.toolCalls ?? []).map((call) => ({
        id: call.id,
        type: 'function',
        function: { name: call.name, arguments: JSON.stringify(call.args) },
      }));
      return { role: 'assistant', content: message.content || null, ...(toolCalls.length > 0 ? { tool_calls: toolCalls } : {}) };
    }
    return { role: 'user', content: message.content };
  });
}

function parseArguments(text:string):Record<string, unknown> {
  try {
    const value = JSON.parse(text) as unknown;
    return value && typeof value === 'object' ? value as Record<string, unknown> : {};
  } catch {
    return {};
  }
}

export function llmClient(settings:Settings):LlmClient {
  const baseUrl = settings.llmBaseUrl.trim() || undefined;
  return settings.provider === 'anthropic'
    ? new AnthropicClient(settings.model, settings.llmKey, baseUrl)
    : new OpenAiClient(settings.model, settings.llmKey, baseUrl);
}

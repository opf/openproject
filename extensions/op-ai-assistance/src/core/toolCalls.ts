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

import type { RunEvent } from '../shared/types';

export const SOFT_LIMIT = 20;
export const HARD_LIMIT = 25;
// A model that repeats a call after the note usually loops: the next one answers now.
const MAX_REPEATS = 1;
export const LIMIT_TEXT = 'No more tool calls. Answer now with what you have.';
export const REPEATED_TEXT = 'You already called this tool with these arguments. No more tool calls: answer now with '
  + 'what you have. The result:';
export const ERROR_TEXT = JSON.stringify({ error: "The tool failed. Check the arguments against the tool's schema." });

export class ToolLimitExceeded extends Error {}

type ToolCallEvent = Extract<RunEvent, { type:'tool_call' }>;

function canonical(args:Record<string, unknown>):string {
  return JSON.stringify(Object.keys(args).sort().map((key) => [key, args[key]]));
}

// The tool calls of one answer: each one is recorded, an identical call gets the earlier
// result, and the number is limited.
export class ToolCalls {
  count = 0;
  private repeats = 0;
  private readonly results = new Map<string, string>();

  constructor(
    private readonly record:(event:ToolCallEvent) => void,
    private readonly now:() => number = () => performance.now(),
  ) {}

  async run(name:string, args:Record<string, unknown>, perform:() => Promise<string>):Promise<string> {
    this.count += 1;
    if (this.count > HARD_LIMIT) throw new ToolLimitExceeded(`more than ${HARD_LIMIT} tool calls`);
    if (this.count > SOFT_LIMIT || this.repeats >= MAX_REPEATS) return this.refuse(name, args);

    const key = `${name}:${canonical(args)}`;
    const earlier = this.results.get(key);
    if (earlier !== undefined) return this.repeat(name, args, earlier);

    const text = await this.perform(name, args, perform);
    this.results.set(key, text);
    return text;
  }

  private async perform(name:string, args:Record<string, unknown>, perform:() => Promise<string>):Promise<string> {
    const started = this.now();
    try {
      const text = await perform();
      const seconds = Math.round((this.now() - started) / 10) / 100;
      this.record({ type: 'tool_call', name, arguments: args, seconds, size: text.length, result: text });
      return text;
    } catch (error) {
      this.record({ type: 'tool_call', name, arguments: args, error: error instanceof Error ? error.message : String(error) });
      return ERROR_TEXT;
    }
  }

  private refuse(name:string, args:Record<string, unknown>):string {
    this.record({ type: 'tool_call', name, arguments: args, refused: true });
    return LIMIT_TEXT;
  }

  private repeat(name:string, args:Record<string, unknown>, text:string):string {
    this.repeats += 1;
    this.record({ type: 'tool_call', name, arguments: args, repeated: true });
    return `${REPEATED_TEXT}\n${text}`;
  }
}

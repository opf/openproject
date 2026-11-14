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

export interface ToolDefinition {
  name:string;
  description:string;
  inputSchema:Record<string, unknown>;
  // The arguments must match the schema exactly.
  strict?:boolean;
}

export interface ToolCall {
  id:string;
  name:string;
  args:Record<string, unknown>;
}

// raw: the provider's own content of an assistant turn. A provider that needs blocks back
// unchanged (Anthropic thinking blocks in a tool loop) sends it instead of content/toolCalls.
export type LlmMessage =
  | { role:'user'; content:string }
  | { role:'assistant'; content:string; toolCalls?:ToolCall[]; raw?:unknown }
  | { role:'tool'; toolCallId:string; name:string; content:string };

export interface LlmRequest {
  system:string;
  messages:LlmMessage[];
  tools:ToolDefinition[];
  // A tool that the model should call now. Providers that cannot force a tool only steer.
  forceTool?:string;
}

export interface LlmTurn {
  text:string;
  toolCalls:ToolCall[];
  raw?:unknown;
}

export interface LlmClient {
  readonly model:string;
  complete(request:LlmRequest):Promise<LlmTurn>;
}

export interface ToolSet {
  definitions:ToolDefinition[];
  call(name:string, args:Record<string, unknown>):Promise<string>;
}

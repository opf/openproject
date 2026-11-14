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

import type { ToolDefinition, ToolSet } from '../core/llmTypes';
import type { Transport, TransportRequest } from './transport';

export class OpenProjectError extends Error {
  constructor(message:string, readonly status:number, readonly identifier?:string) {
    super(message);
  }
}

export type Hal = Record<string, unknown> & {
  _links?:Record<string, { href?:string | null; title?:string } | undefined>;
  _embedded?:Record<string, unknown>;
};

export class OpenProjectClient {
  constructor(private readonly transport:Transport) {}

  get<T = Hal>(path:string):Promise<T> {
    return this.send<T>({ method: 'GET', path });
  }

  post<T = Hal>(path:string, body:unknown):Promise<T> {
    return this.send<T>({ method: 'POST', path, body: JSON.stringify(body) });
  }

  patch<T = Hal>(path:string, body:unknown):Promise<T> {
    return this.send<T>({ method: 'PATCH', path, body: JSON.stringify(body) });
  }

  async raw(request:TransportRequest):Promise<{ status:number; body:string }> {
    return this.transport(request);
  }

  private async send<T>(request:TransportRequest):Promise<T> {
    const { status, body } = await this.transport(request);
    const json = body ? JSON.parse(body) as Hal : {};
    if (status >= 400) {
      const message = typeof json.message === 'string' ? json.message : `OpenProject answered ${status}.`;
      throw new OpenProjectError(message, status, typeof json.errorIdentifier === 'string' ? json.errorIdentifier : undefined);
    }
    return json as T;
  }
}

export class McpUnavailable extends Error {}

interface McpTool {
  name:string;
  description?:string;
  inputSchema?:Record<string, unknown>;
  annotations?:{ readOnlyHint?:boolean; read_only_hint?:boolean };
}

interface RpcResponse<T> {
  result?:T;
  error?:{ message?:string };
}

// OpenProject's MCP server: stateless JSON-RPC on POST /mcp, as the signed-in user.
export class McpClient {
  private nextId = 1;

  constructor(private readonly op:OpenProjectClient) {}

  async readOnlyTools():Promise<ToolSet> {
    const { tools } = await this.rpc<{ tools?:McpTool[] }>('tools/list', {});
    const definitions:ToolDefinition[] = (tools ?? [])
      .filter((tool) => tool.annotations?.readOnlyHint === true || tool.annotations?.read_only_hint === true)
      .map((tool) => ({
        name: tool.name,
        description: tool.description ?? tool.name,
        inputSchema: tool.inputSchema ?? { type: 'object', properties: {} },
      }));
    const allowed = new Set(definitions.map((definition) => definition.name));

    return {
      definitions,
      call: async (name, args) => {
        if (!allowed.has(name)) throw new Error(`The tool ${name} is not offered.`);
        const result = await this.rpc<{ content?:{ type:string; text?:string }[]; structuredContent?:unknown; isError?:boolean }>(
          'tools/call',
          { name, arguments: args },
        );
        const text = (result.content ?? []).filter((item) => item.type === 'text').map((item) => item.text ?? '').join('\n')
          || JSON.stringify(result.structuredContent ?? {});
        if (result.isError) throw new Error(text.slice(0, 500));
        return text;
      },
    };
  }

  private async rpc<T>(method:string, params:Record<string, unknown>):Promise<T> {
    const id = this.nextId;
    this.nextId += 1;
    const { status, body } = await this.op.raw({
      method: 'POST',
      path: '/mcp',
      body: JSON.stringify({ jsonrpc: '2.0', id, method, params }),
    });
    if (status === 404) throw new McpUnavailable('The MCP server of this instance is not enabled.');
    if (status === 401 || status === 403) throw new McpUnavailable('The MCP server does not accept this sign-in.');
    if (status >= 400) throw new Error(`The MCP server answered ${status}.`);

    const response = JSON.parse(body) as RpcResponse<T>;
    if (response.error || response.result === undefined) throw new Error(response.error?.message ?? 'The MCP call failed.');
    return response.result;
  }
}

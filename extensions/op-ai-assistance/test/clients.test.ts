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

import { describe, expect, it, vi } from 'vitest';

vi.mock('webextension-polyfill', () => ({ default: {} }));

const { McpClient, McpUnavailable, OpenProjectClient } = await import('../src/clients/openproject');
const { appPath, isAllowedPath, tokenTransport } = await import('../src/clients/transport');
const { ApplyError, applyProposal, loadWorkPackage } = await import('../src/clients/workPackages');
const { storableEvent } = await import('../src/shared/storage');
import type { Transport, TransportRequest } from '../src/clients/transport';
import type { Proposal } from '../src/shared/types';

function fakeTransport(routes:Record<string, (request:TransportRequest) => unknown>):{ transport:Transport; requests:TransportRequest[] } {
  const requests:TransportRequest[] = [];
  const transport:Transport = (request) => {
    requests.push(request);
    const route = routes[`${request.method} ${request.path.split('?')[0]}`];
    if (!route) return Promise.resolve({ status: 404, body: '{"message":"not found"}' });
    const result = route(request);
    return Promise.resolve(typeof result === 'object' && result && 'status' in result
      ? result as { status:number; body:string }
      : { status: 200, body: JSON.stringify(result) });
  };
  return { transport, requests };
}

describe('McpClient', () => {
  const tools = [
    { name: 'search_work_packages', description: 'Search', inputSchema: { type: 'object' }, annotations: { readOnlyHint: true } },
    { name: 'update_work_package', description: 'Update', inputSchema: { type: 'object' }, annotations: { readOnlyHint: false } },
    { name: 'create_work_package', description: 'Create', inputSchema: { type: 'object' } },
  ];

  it('offers only the read-only tools and refuses calls to any other tool', async () => {
    const { transport, requests } = fakeTransport({
      'POST /mcp': (request) => {
        const rpc = JSON.parse(request.body ?? '{}') as { id:number; method:string };
        return rpc.method === 'tools/list'
          ? { jsonrpc: '2.0', id: rpc.id, result: { tools } }
          : { jsonrpc: '2.0', id: rpc.id, result: { content: [{ type: 'text', text: '{"total":3}' }] } };
      },
    });
    const toolSet = await new McpClient(new OpenProjectClient(transport)).readOnlyTools();

    expect(toolSet.definitions.map((tool) => tool.name)).toEqual(['search_work_packages']);
    await expect(toolSet.call('search_work_packages', { open: true })).resolves.toBe('{"total":3}');
    await expect(toolSet.call('update_work_package', {})).rejects.toThrow('not offered');
    expect(requests.filter((request) => request.body?.includes('tools/call'))).toHaveLength(1);
  });

  it('reports a disabled MCP server', async () => {
    const { transport } = fakeTransport({});
    await expect(new McpClient(new OpenProjectClient(transport)).readOnlyTools()).rejects.toBeInstanceOf(McpUnavailable);
  });
});

describe('isAllowedPath', () => {
  it('lets the proxy reach only API v3 and MCP', () => {
    expect(isAllowedPath('/api/v3/work_packages/1')).toBe(true);
    expect(isAllowedPath('/mcp')).toBe(true);
    expect(isAllowedPath('/my/account')).toBe(false);
    expect(isAllowedPath('/mcpx')).toBe(false);
    expect(isAllowedPath('https://evil.example/api/v3/')).toBe(false);
    expect(isAllowedPath('//evil.example/api/v3/')).toBe(false);
    expect(isAllowedPath('/api/v3/../../admin')).toBe(false);
    expect(isAllowedPath('/api/v3/%2e%2e/%2e%2e/admin')).toBe(false);
    expect(isAllowedPath('/api/v3/work_packages?filters=%5B%5D')).toBe(true);
  });
});

describe('base path', () => {
  it('removes the base path of an instance under a sub-path from API hrefs', () => {
    expect(appPath('/openproject/api/v3/projects/1/available_assignees', '/openproject')).toBe('/api/v3/projects/1/available_assignees');
    expect(appPath('/api/v3/statuses', '/openproject')).toBe('/api/v3/statuses');
    expect(appPath('/api/v3/statuses', '')).toBe('/api/v3/statuses');
  });

  it('sends token requests below the base path', async () => {
    const fetchMock = vi.fn((_url:string, _init?:RequestInit) => Promise.resolve(new Response('{}', { status: 200 })));
    vi.stubGlobal('fetch', fetchMock);
    try {
      const transport = tokenTransport('https://op.example.com/openproject/', 'secret');
      await transport({ method: 'GET', path: '/openproject/api/v3/statuses' });
      await expect(transport({ method: 'GET', path: '/openproject/admin' })).rejects.toThrow('not allowed');
      expect(fetchMock).toHaveBeenCalledTimes(1);
      expect(fetchMock.mock.calls[0]?.[0]).toBe('https://op.example.com/openproject/api/v3/statuses');
    } finally {
      vi.unstubAllGlobals();
    }
  });
});

describe('loadWorkPackage', () => {
  it('still loads the context when the user may not edit the work package', async () => {
    const { transport } = fakeTransport({
      'GET /api/v3/work_packages/7': () => ({
        id: 7,
        lockVersion: 1,
        subject: 'Plan',
        description: { raw: 'Text' },
        _links: { status: { href: '/api/v3/statuses/1', title: 'New' }, activities: { href: '/api/v3/work_packages/7/activities' } },
      }),
      'POST /api/v3/work_packages/7/form': () => ({ status: 403, body: '{"message":"forbidden"}' }),
      'GET /api/v3/statuses': () => ({ _embedded: { elements: [{ isClosed: false, isDefault: true, _links: { self: { href: '/api/v3/statuses/1' } } }] } }),
      'GET /api/v3/work_packages/7/activities': () => ({ _embedded: { elements: [] } }),
      'GET /api/v3/work_packages': () => ({ _embedded: { elements: [] } }),
      'GET /api/v3/relations': () => ({ _embedded: { elements: [] } }),
    });

    const loaded = await loadWorkPackage(new OpenProjectClient(transport), '7');
    expect(loaded.optionsData.writable).toEqual([]);
    expect(loaded.context.work_package).toMatchObject({ subject: 'Plan', status: 'New', default_status: true });
  });
});

describe('storableEvent', () => {
  it('drops the full prompt and the tool results before an event is stored', () => {
    expect(storableEvent({ type: 'request', model: 'm', system: 'x'.repeat(50), message: 'q', tools: 2 }))
      .toMatchObject({ system: '(50 characters, not stored)', message: 'q' });
    expect(storableEvent({ type: 'tool_call', name: 'search', arguments: {}, size: 9, result: 'big' }))
      .toEqual({ type: 'tool_call', name: 'search', arguments: {}, size: 9, result: undefined });
  });
});

describe('applyProposal', () => {
  const workPackage = {
    id: 7,
    lockVersion: 4,
    description: { raw: 'Old ![x](/api/v3/attachments/3/content)' },
    _links: { addComment: { href: '/api/v3/work_packages/7/activities' } },
  };
  const proposal = (actions:Proposal['actions'], extra:Partial<Proposal> = {}):Proposal => ({
    id: 'p', text: 't', severity: null, area: null, evidence: [], actions, state: 'open', ...extra,
  });

  it('sends the attributes in one PATCH with the current lockVersion, then the comment', async () => {
    const { transport, requests } = fakeTransport({
      'GET /api/v3/work_packages/7': () => workPackage,
      'PATCH /api/v3/work_packages/7': () => ({}),
      'POST /api/v3/work_packages/7/activities': () => ({}),
    });
    await applyProposal(new OpenProjectClient(transport), '7', proposal([
      { key: 'status', value: '/api/v3/statuses/7', label: 'In progress' },
      { key: 'due_date', value: '2026-12-24', label: '2026-12-24' },
      { key: 'comment', value: 'Moved on.', label: 'Moved on.' },
    ]));

    const patch = requests.find((request) => request.method === 'PATCH');
    expect(JSON.parse(patch?.body ?? '{}')).toEqual({ lockVersion: 4, dueDate: '2026-12-24', _links: { status: { href: '/api/v3/statuses/7' } } });
    expect(JSON.parse(requests.at(-1)?.body ?? '{}')).toEqual({ comment: { raw: 'Moved on.' } });
  });

  it('refuses a description that drops an attachment, or that is based on an older description', async () => {
    const { transport } = fakeTransport({ 'GET /api/v3/work_packages/7': () => workPackage });
    const op = new OpenProjectClient(transport);

    await expect(applyProposal(op, '7', proposal([{ key: 'description', value: 'New', label: 'New' }])))
      .rejects.toThrow('removes images');
    await expect(applyProposal(op, '7', proposal([{ key: 'description', value: 'New', label: 'New' }], { baseDescription: 'Older' })))
      .rejects.toBeInstanceOf(ApplyError);
  });

  it('turns a lock conflict into a clear message', async () => {
    const { transport } = fakeTransport({
      'GET /api/v3/work_packages/7': () => workPackage,
      'PATCH /api/v3/work_packages/7': () => ({ status: 409, body: '{"message":"conflict"}' }),
    });
    await expect(applyProposal(new OpenProjectClient(transport), '7', proposal([{ key: 'subject', value: 'S', label: 'S' }])))
      .rejects.toThrow('changed after this proposal');
  });
});

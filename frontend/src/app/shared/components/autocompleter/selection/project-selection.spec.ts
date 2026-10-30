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

import { TestBed } from '@angular/core/testing';
import { provideHttpClient } from '@angular/common/http';
import { HttpTestingController, provideHttpClientTesting } from '@angular/common/http/testing';
import { States } from 'core-app/core/states/states.service';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { HalResourceService } from 'core-app/features/hal/services/hal-resource.service';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import {
  createProjectSelectionAdapter,
  decodeProjectSelection,
  projectSelectionToResource,
} from './project-selection';

describe('decodeProjectSelection', () => {
  let halResourceService:HalResourceService;

  beforeEach(() => {
    TestBed.configureTestingModule({
      providers: [States, provideHttpClient(), provideHttpClientTesting()],
    });
    halResourceService = TestBed.inject(HalResourceService);
  });

  it.each([null, undefined, { href: null }])('decodes %o as an empty selection', (raw) => {
    expect(decodeProjectSelection(raw)).toEqual({ ok: true, value: null });
  });

  it.each([0, 7, '7'])('decodes the scalar ID %o as a reference', (id) => {
    expect(decodeProjectSelection(id)).toEqual({ ok: true, value: { kind: 'reference', reference: { id } } });
  });

  it('decodes a complete DTO as an option', () => {
    const option = { id: 7, name: 'Apollo', href: '/api/v3/projects/7' };

    expect(decodeProjectSelection(option)).toEqual({ ok: true, value: { kind: 'option', option } });
  });

  it('keeps only the typed fields of an option', () => {
    const decoded = decodeProjectSelection({
      id: 7,
      name: 'Apollo',
      href: '/api/v3/projects/7',
      ancestors: [],
      disabled: false,
    });

    expect(decoded).toEqual({
      ok: true,
      value: { kind: 'option', option: { id: 7, name: 'Apollo', href: '/api/v3/projects/7' } },
    });
  });

  it('decodes an identity without a name as a reference', () => {
    expect(decodeProjectSelection({ id: 7, href: '/api/v3/projects/7' })).toEqual({
      ok: true,
      value: { kind: 'reference', reference: { id: 7, href: '/api/v3/projects/7' } },
    });
  });

  it('decodes a link-only object as a reference', () => {
    expect(decodeProjectSelection({ href: '/api/v3/projects/7', name: 'Apollo' })).toEqual({
      ok: true,
      value: { kind: 'reference', reference: { href: '/api/v3/projects/7', name: 'Apollo' } },
    });
  });

  it('decodes a loaded HAL project as an option through its getters', () => {
    const project = halResourceService.createHalResourceOfType('project', {
      id: 7,
      name: 'Apollo',
      _links: { self: { href: '/api/v3/projects/7' } },
    });

    expect(decodeProjectSelection(project)).toEqual({
      ok: true,
      value: { kind: 'option', option: { id: '7', name: 'Apollo', href: '/api/v3/projects/7' } },
    });
  });

  it('decodes a HAL link without a name as a reference', () => {
    const linked = halResourceService.createHalResource({ _links: { self: { href: '/api/v3/projects/7' } } }, false);

    expect(decodeProjectSelection(linked)).toEqual({
      ok: true,
      value: { kind: 'reference', reference: { id: '7', href: '/api/v3/projects/7' } },
    });
  });

  it.each([
    { id: '7', name: 7 },
    { id: 7, name: 'Apollo', href: 7 },
    { id: 7, name: 'Apollo', href: '' },
    { id: false },
    { id: Number.NaN, href: '/api/v3/projects/7' },
    { unrelated: true },
    new Date(),
    true,
    Number.POSITIVE_INFINITY,
  ])('rejects %o as an invalid shape', (raw) => {
    expect(decodeProjectSelection(raw)).toEqual({ ok: false, issue: { code: 'invalid-shape' } });
  });

  it('rejects a draft without identity as unsupported', () => {
    expect(decodeProjectSelection({ id: null, href: null, name: 'New project' })).toEqual({
      ok: false,
      issue: { code: 'unsupported-selection' },
    });
  });

  it.each([[[]], [[{ id: 7, name: 'Apollo', href: '/api/v3/projects/7' }]]])(
    'rejects the array %o as the wrong cardinality',
    (raw) => {
      expect(decodeProjectSelection(raw)).toEqual({ ok: false, issue: { code: 'wrong-cardinality' } });
    },
  );
});

describe('createProjectSelectionAdapter', () => {
  beforeEach(() => {
    vi.stubGlobal('ErrorReporter', { captureMessage: vi.fn() });
  });

  afterEach(() => {
    vi.unstubAllGlobals();
  });

  it('starts empty and keeps an invalid change from emitting', () => {
    const adapter = createProjectSelectionAdapter();
    const emitted = vi.fn();
    adapter.changes$.subscribe(emitted);

    adapter.bridge.accept({ id: '7', name: 7 });

    expect(adapter.state).toEqual({ kind: 'invalid', issue: { code: 'invalid-shape' }, lastAccepted: null });
    expect(emitted).not.toHaveBeenCalled();
  });

  it('displays a typed value through its raw model', () => {
    const adapter = createProjectSelectionAdapter();
    const option = { id: 7, name: 'Apollo', href: '/api/v3/projects/7' };

    adapter.setValue({ kind: 'option', option });

    expect(adapter.bridge.model).toEqual(option);
  });

  it('compares raw items by href, then ID, never by missing identity', () => {
    const { compareWith, trackBy } = createProjectSelectionAdapter().bridge;

    expect(compareWith({ href: '/api/v3/projects/7', name: 'A' }, { href: '/api/v3/projects/7', name: 'B' })).toBe(true);
    expect(compareWith({ id: 0, href: null }, { id: '0' })).toBe(true);
    expect(compareWith({ name: 'Apollo' }, { name: 'Apollo' })).toBe(false);
    expect(compareWith({ id: 7, href: '/api/v3/projects/7' }, { id: 7, href: '/api/v3/projects/8' })).toBe(false);
    expect(trackBy({ id: 0, href: null })).toBe(0);
    expect(trackBy({ id: 7, href: '/api/v3/projects/7' })).toBe('/api/v3/projects/7');
    expect(trackBy({ name: 'Apollo' })).toBeUndefined();
  });
});

describe('projectSelectionToResource', () => {
  let deps:{ halResourceService:HalResourceService; apiV3Service:ApiV3Service };
  let http:HttpTestingController;

  beforeEach(() => {
    TestBed.configureTestingModule({
      providers: [States, provideHttpClient(), provideHttpClientTesting()],
    });
    deps = { halResourceService: TestBed.inject(HalResourceService), apiV3Service: TestBed.inject(ApiV3Service) };
    http = TestBed.inject(HttpTestingController);
  });

  afterEach(() => {
    http.expectNone(() => true);
    http.verify();
  });

  it('returns null for an empty selection', () => {
    expect(projectSelectionToResource(null, deps)).toBeNull();
  });

  it('builds a project resource from an option, keeping its name', () => {
    const resource = projectSelectionToResource(
      { kind: 'option', option: { id: 7, name: 'Apollo', href: '/api/v3/projects/7' } },
      deps,
    );

    expect(resource).toBeInstanceOf(HalResource);
    expect(resource?.$halType).toBe('project');
    expect(resource?.href).toBe('/api/v3/projects/7');
    expect(resource?.name).toBe('Apollo');
  });

  it('builds a reference by ID from the projects path', () => {
    const resource = projectSelectionToResource({ kind: 'reference', reference: { id: 7 } }, deps);

    expect(resource?.$halType).toBe('project');
    expect(resource?.href).toBe('/api/v3/projects/7');
    expect(resource?.id).toBe('7');
  });

  it('keeps the supplied href and name of a reference', () => {
    const resource = projectSelectionToResource(
      { kind: 'reference', reference: { href: '/api/v3/projects/by-link', name: 'Linked' } },
      deps,
    );

    expect(resource?.href).toBe('/api/v3/projects/by-link');
    expect(resource?.name).toBe('Linked');
  });
});

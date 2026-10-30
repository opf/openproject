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
  LabelSelection,
  compareLabels,
  createLabelSelectionAdapter,
  decodeLabelSelections,
  labelSelectionToResources,
} from './label-selection';

describe('decodeLabelSelections', () => {
  it.each([null, undefined])('decodes %o as empty on load and change', (raw) => {
    expect(decodeLabelSelections(raw, 'load')).toEqual({ ok: true, value: [] });
    expect(decodeLabelSelections(raw, 'change')).toEqual({ ok: true, value: [] });
  });

  it('decodes an empty relationship as empty on load only', () => {
    expect(decodeLabelSelections({ href: null }, 'load')).toEqual({ ok: true, value: [] });
    expect(decodeLabelSelections({ href: null }, 'change')).toEqual({ ok: false, issue: { code: 'wrong-cardinality' } });
  });

  it.each([0, 7, '7'])('decodes the scalar %o as one reference on load', (id) => {
    expect(decodeLabelSelections(id, 'load')).toEqual({
      ok: true,
      value: [{ kind: 'reference', reference: { id } }],
    });
  });

  it('rejects a scalar change as the wrong cardinality', () => {
    expect(decodeLabelSelections('7', 'change')).toEqual({ ok: false, issue: { code: 'wrong-cardinality' } });
  });

  it('keeps a mixed array of reference, draft and option in order', () => {
    const option = { id: 3, name: 'Bug', href: '/api/v3/labels/3' };

    expect(decodeLabelSelections([
      { id: 7, href: '/api/v3/labels/7' },
      { id: null, href: null, name: '  New ' },
      option,
    ], 'change')).toEqual({
      ok: true,
      value: [
        { kind: 'reference', reference: { id: 7, href: '/api/v3/labels/7' } },
        { kind: 'draft', draft: { name: 'New' } },
        { kind: 'option', option },
      ],
    });
  });

  it('preserves duplicates and ID 0', () => {
    expect(decodeLabelSelections([0, 0], 'change')).toEqual({
      ok: true,
      value: [
        { kind: 'reference', reference: { id: 0 } },
        { kind: 'reference', reference: { id: 0 } },
      ],
    });
  });

  it('rejects the whole array and reports the failing index', () => {
    expect(decodeLabelSelections([
      { id: 7, name: 'Bug', href: null },
      { id: null, href: null, name: 'New' },
      { id: '9', name: 9 },
      { id: 4, name: 'Fine', href: null },
    ], 'change')).toEqual({ ok: false, issue: { code: 'invalid-shape', index: 2 } });
  });

  it.each([
    { id: null, href: null, name: '   ' },
    { id: null, href: null },
    { name: 7 },
    { unrelated: true },
    { href: null },
    new Date(),
    [[]],
    true,
  ])('rejects the entry %o as an invalid shape', (entry) => {
    expect(decodeLabelSelections([entry], 'change')).toEqual({ ok: false, issue: { code: 'invalid-shape', index: 0 } });
  });

  it('never treats an entry with an ID as a draft', () => {
    expect(decodeLabelSelections([{ id: 0, href: null, name: 'New' }], 'change')).toEqual({
      ok: true,
      value: [{ kind: 'option', option: { id: 0, name: 'New', href: null } }],
    });
  });

  it('keeps the empty name of a HAL label', () => {
    TestBed.configureTestingModule({ providers: [States, provideHttpClient(), provideHttpClientTesting()] });
    const label = TestBed.inject(HalResourceService).createHalResourceOfType('Label', {
      id: 5,
      name: '',
      _links: { self: { href: '/api/v3/labels/5' } },
    });

    expect(decodeLabelSelections([label], 'load')).toEqual({
      ok: true,
      value: [{ kind: 'option', option: { id: '5', name: '', href: '/api/v3/labels/5' } }],
    });
  });

  it('decodes a link-only HAL label as a reference', () => {
    TestBed.configureTestingModule({ providers: [States, provideHttpClient(), provideHttpClientTesting()] });
    const label = TestBed.inject(HalResourceService).createHalResource({ _links: { self: { href: '/api/v3/labels/5' } } }, false);

    expect(decodeLabelSelections([label], 'load')).toEqual({
      ok: true,
      value: [{ kind: 'reference', reference: { id: '5', href: '/api/v3/labels/5' } }],
    });
  });

  it('decodes a HAL draft label as a draft', () => {
    TestBed.configureTestingModule({ providers: [States, provideHttpClient(), provideHttpClientTesting()] });
    const draft = TestBed.inject(HalResourceService).createHalResourceOfType('Label', { id: null, href: null, name: 'New' });

    expect(decodeLabelSelections([draft], 'load')).toEqual({
      ok: true,
      value: [{ kind: 'draft', draft: { name: 'New' } }],
    });
  });
});

describe('compareLabels', () => {
  it('compares by ID or href when both have identity', () => {
    expect(compareLabels({ id: 1 }, { id: 1 })).toBe(true);
    expect(compareLabels({ id: 1 }, { id: '1' })).toBe(true);
    expect(compareLabels({ href: '/a', name: 'A' }, { href: '/a', name: 'B' })).toBe(true);
    expect(compareLabels({ id: 1, name: 'A', href: null }, { id: 2, name: 'B', href: null })).toBe(false);
  });

  it('compares two complete labels by name even when their identities differ', () => {
    expect(compareLabels({ id: 1, name: 'Bug', href: '/1' }, { id: 2, name: 'bug', href: '/2' })).toBe(true);
    expect(compareLabels({ id: 1, name: 'Bug', href: '/1' }, { id: 1, name: 'Fix', href: '/1' })).toBe(false);
  });

  it('compares names case-insensitively only for complete labels', () => {
    expect(compareLabels({ id: null, href: null, name: 'A' }, { id: null, href: null, name: 'a' })).toBe(true);
    expect(compareLabels({ id: 1, href: '/1', name: 'A' }, { id: null, href: null, name: 'a' })).toBe(true);
    expect(compareLabels({ name: 'A' }, { name: 'a' })).toBe(false);
    expect(compareLabels({ id: 1 }, { id: null, href: null, name: 'a' })).toBe(false);
  });

  it('never matches missing identity or names and does not throw', () => {
    expect(compareLabels({}, {})).toBe(false);
    expect(compareLabels(null, undefined)).toBe(false);
    expect(compareLabels({ id: null, href: null }, { id: null, href: null })).toBe(false);
    expect(compareLabels('x', 3)).toBe(false);
  });
});

describe('createLabelSelectionAdapter', () => {
  beforeEach(() => {
    vi.stubGlobal('ErrorReporter', { captureMessage: vi.fn() });
  });

  afterEach(() => {
    vi.unstubAllGlobals();
  });

  it('accepts a scalar on load but rejects it as a change', () => {
    const loaded = createLabelSelectionAdapter();
    loaded.bridge.load('7');
    expect(loaded.state).toEqual({ kind: 'ready', value: [{ kind: 'reference', reference: { id: '7' } }] });

    const changed = createLabelSelectionAdapter();
    const emitted = vi.fn();
    changed.changes$.subscribe(emitted);
    changed.bridge.accept('7');
    expect(changed.state).toEqual({ kind: 'invalid', issue: { code: 'wrong-cardinality' }, lastAccepted: [] });
    expect(changed.bridge.rejected).toBe('7');
    expect(emitted).not.toHaveBeenCalled();
  });

  it('keeps the last accepted selection after an invalid change', () => {
    const adapter = createLabelSelectionAdapter();
    const draft = { id: null, href: null, name: 'New' };
    adapter.bridge.accept([draft]);

    adapter.bridge.accept([{ id: '1', name: 1 }]);

    expect(adapter.state).toMatchObject({ kind: 'invalid', issue: { code: 'invalid-shape', index: 0 } });
    expect(adapter.bridge.model).toEqual([draft]);
  });

  it('emits typed selections for a valid change', () => {
    const adapter = createLabelSelectionAdapter();
    const emitted = vi.fn();
    adapter.changes$.subscribe(emitted);

    adapter.bridge.accept([{ id: null, href: null, name: 'New' }]);

    expect(emitted).toHaveBeenCalledExactlyOnceWith([{ kind: 'draft', draft: { name: 'New' } }]);
  });

  it('tracks by identity, falling back to the name', () => {
    const { trackBy } = createLabelSelectionAdapter().bridge;

    expect(trackBy({ id: 1, href: '/1', name: 'A' })).toBe('/1');
    expect(trackBy({ id: null, href: null, name: 'New' })).toBe('New');
    expect(trackBy({})).toBeUndefined();
    expect(trackBy(false)).toBeUndefined();
  });
});

describe('labelSelectionToResources', () => {
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

  it('converts every kind in order without requests', () => {
    const selections:LabelSelection[] = [
      { kind: 'reference', reference: { id: 7 } },
      { kind: 'draft', draft: { name: 'New' } },
      { kind: 'option', option: { id: 3, name: 'Bug', href: '/api/v3/labels/3' } },
      { kind: 'reference', reference: { href: '/api/v3/labels/9', name: 'Nine' } },
    ];

    const resources = labelSelectionToResources(selections, deps);

    expect(resources.every((resource) => resource instanceof HalResource && resource.$halType === 'Label')).toBe(true);
    expect(resources.map((resource) => resource.href)).toEqual(['/api/v3/labels/7', null, '/api/v3/labels/3', '/api/v3/labels/9']);
    expect(resources[1].name).toBe('New');
    expect(resources[1].id).toBeNull();
    expect(resources[2].name).toBe('Bug');
    expect(resources[3].name).toBe('Nine');
  });

  it('builds the href of an option without one from the labels path', () => {
    const [resource] = labelSelectionToResources([{ kind: 'option', option: { id: 4, name: 'Bug', href: null } }], deps);

    expect(resource.href).toBe('/api/v3/labels/4');
    expect(resource.name).toBe('Bug');
  });
});

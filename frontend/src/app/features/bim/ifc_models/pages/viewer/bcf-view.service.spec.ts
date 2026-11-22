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
import { firstValueFrom } from 'rxjs';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { ViewerBridgeService } from 'core-app/features/bim/bcf/bcf-viewer-bridge/viewer-bridge.service';
import { IsolatedQuerySpace } from 'core-app/features/work-packages/directives/query-space/isolated-query-space';
import { QueryResource } from 'core-app/features/hal/resources/query-resource';
import { WorkPackageCollectionResource } from 'core-app/features/hal/resources/wp-collection-resource';
import { BcfViewService, BcfViewState } from './bcf-view.service';

describe('BcfViewService', () => {
  const build = (shouldShowViewer:boolean) => {
    TestBed.configureTestingModule({
      providers: [
        BcfViewService,
        { provide: IsolatedQuerySpace, useValue: {} },
        { provide: I18nService, useValue: { t: (key:string) => key } },
        { provide: ViewerBridgeService, useValue: { shouldShowViewer } },
      ],
    });
    return TestBed.inject(BcfViewService);
  };

  const query = (displayRepresentation:string|undefined) => ({ displayRepresentation }) as QueryResource;

  const initialized = (shouldShowViewer:boolean, saved:string|undefined) => {
    const service = build(shouldShowViewer);
    service.initialize(query(saved), {} as WorkPackageCollectionResource);
    return service;
  };

  it.each(['viewer', 'splitCards', 'splitTable', 'cards', 'table'] as BcfViewState[])(
    'keeps a saved %s view when a viewer can be shown',
    async (state) => {
      const service = initialized(true, state);

      expect(service.currentViewerState()).toBe(state);
      expect(await firstValueFrom(service.live$())).toBe(state);
    },
  );

  it.each([
    ['viewer', 'cards'],
    ['splitCards', 'cards'],
    ['splitTable', 'table'],
    ['cards', 'cards'],
    ['table', 'table'],
  ] as [BcfViewState, BcfViewState][])('shows a saved %s view as %s when no viewer can be shown', async (state, expected) => {
    const service = initialized(false, state);

    expect(service.currentViewerState()).toBe(expected);
    expect(await firstValueFrom(service.live$())).toBe(expected);
    expect(service.valueFromQuery(query(state))).toBe(expected);
  });

  it('defaults to cards without a viewer', () => {
    expect(initialized(false, undefined).currentViewerState()).toBe('cards');
  });

  it('defaults to viewer and cards with a viewer', () => {
    expect(initialized(true, undefined).currentViewerState()).toBe('splitCards');
  });

  it.each([undefined, 'gantt'])('writes the view to a query saved with %s', (saved) => {
    const service = initialized(true, 'cards');

    expect(service.hasChanged(query(saved))).toBe(true);
  });

  it('switches to the view that can be shown when no viewer is available', () => {
    const service = initialized(false, 'cards');

    service.update('splitTable');

    expect(service.currentViewerState()).toBe('table');
  });

  it('keeps the saved view of a query whose view cannot be shown', () => {
    const saved = query('viewer');
    const service = initialized(false, 'viewer');

    expect(service.hasChanged(saved)).toBe(false);
    service.applyToQuery(saved);
    expect(saved.displayRepresentation).toBe('viewer');

    service.update('table');

    expect(service.hasChanged(saved)).toBe(true);
    service.applyToQuery(saved);
    expect(saved.displayRepresentation).toBe('table');
  });
});

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
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { TestBed } from '@angular/core/testing';
import { waitFor } from '@testing-library/dom';
import { Subject } from 'rxjs';
import { CurrentProjectService } from 'core-app/core/current-project/current-project.service';
import { BcfViewService } from 'core-app/features/bim/ifc_models/pages/viewer/bcf-view.service';
import { WorkPackagesListService } from 'core-app/features/work-packages/components/wp-list/wp-list.service';
import {
  WorkPackageStatesInitializationService,
} from 'core-app/features/work-packages/components/wp-list/wp-states-initialization.service';
import {
  QueryParamListenerService,
} from 'core-app/features/work-packages/components/wp-query/query-param-listener.service';
import { QueryResource } from 'core-app/features/hal/resources/query-resource';
import { BcfContentRightEntryComponent } from './bcf-content-right-entry.component';

describe('BcfContentRightEntryComponent', () => {
  let loads:{ resolve:(query:QueryResource) => void, reject:(error:unknown) => void }[];
  let listener:{
    observe$:Subject<unknown>,
    reconcileWithUrl:ReturnType<typeof vi.fn>,
    removeQueryChangeListener:ReturnType<typeof vi.fn>,
  };
  let bcfView:{ initialize:ReturnType<typeof vi.fn> };

  const query = { results: {} } as QueryResource;

  const loadCurrentQueryFromParams = vi.fn(() => new Promise<QueryResource>((resolve, reject) => {
    loads.push({ resolve, reject });
  }));

  const createComponent = () => {
    const fixture = TestBed.createComponent(BcfContentRightEntryComponent);
    fixture.detectChanges();
    return fixture;
  };

  beforeEach(() => {
    loads = [];
    loadCurrentQueryFromParams.mockClear();
    bcfView = { initialize: vi.fn() };
    listener = {
      observe$: new Subject<unknown>(),
      reconcileWithUrl: vi.fn(),
      removeQueryChangeListener: vi.fn(),
    };

    TestBed.configureTestingModule({
      declarations: [BcfContentRightEntryComponent],
      providers: [
        { provide: WorkPackagesListService, useValue: { loadCurrentQueryFromParams } },
        { provide: WorkPackageStatesInitializationService, useValue: { initialize: vi.fn() } },
        { provide: CurrentProjectService, useValue: { identifier: 'demo' } },
      ],
    });

    TestBed.overrideComponent(BcfContentRightEntryComponent, {
      set: {
        template: '',
        hostDirectives: [],
        providers: [
          { provide: BcfViewService, useValue: bcfView },
          { provide: QueryParamListenerService, useValue: listener },
        ],
      },
    });
  });

  it('reconciles with the URL once, after the initial load resolves', async () => {
    createComponent();

    expect(listener.reconcileWithUrl).not.toHaveBeenCalled();

    loads[0].resolve(query);

    await waitFor(() => expect(listener.reconcileWithUrl).toHaveBeenCalledTimes(1));
  });

  it('reconciles with the URL after the initial load fails', async () => {
    createComponent();

    loads[0].reject(new Error('query failed'));

    await waitFor(() => expect(listener.reconcileWithUrl).toHaveBeenCalledTimes(1));
  });

  it('reloads on URL changes without reconciling again', async () => {
    createComponent();
    loads[0].resolve(query);
    await waitFor(() => expect(listener.reconcileWithUrl).toHaveBeenCalledTimes(1));

    listener.observe$.next('{"dr":"cards"}');
    loads[1].resolve(query);

    await waitFor(() => expect(bcfView.initialize).toHaveBeenCalledTimes(2));
    expect(listener.reconcileWithUrl).toHaveBeenCalledTimes(1);
  });

  it('stops reloading once destroyed', () => {
    const fixture = createComponent();

    fixture.destroy();
    listener.observe$.next('{"dr":"cards"}');

    expect(loadCurrentQueryFromParams).toHaveBeenCalledTimes(1);
  });
});

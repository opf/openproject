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
import { Subject } from 'rxjs';
import { NavigationService } from 'core-app/core/navigation/navigation.service';
import { UrlParamsService } from 'core-app/core/navigation/url-params.service';
import {
  WorkPackagesListChecksumService,
} from 'core-app/features/work-packages/components/wp-list/wp-list-checksum.service';
import { WorkPackagesListService } from 'core-app/features/work-packages/components/wp-list/wp-list.service';
import { UrlParamsHelperService } from 'core-app/features/work-packages/components/wp-query/url-params-helper';
import { QueryParamListenerService } from './query-param-listener.service';

describe('QueryParamListenerService', () => {
  const cardsProps = '{"dr":"cards"}';
  const splitCardsProps = '{"dr":"splitCards"}';

  let originalUrl:string;
  let urlChanged$:Subject<string>;
  let listener:QueryParamListenerService;
  let checksum:WorkPackagesListChecksumService;
  let emitted:unknown[];

  const navigateTo = (search:string) => {
    window.history.replaceState(null, '', `${window.location.pathname}${search}`);
    urlChanged$.next(window.location.href);
  };

  beforeEach(() => {
    originalUrl = window.location.href;
    window.history.replaceState(null, '', window.location.pathname);
    urlChanged$ = new Subject<string>();

    TestBed.configureTestingModule({
      providers: [
        QueryParamListenerService,
        WorkPackagesListChecksumService,
        UrlParamsService,
        { provide: NavigationService, useValue: { urlChanged$ } },
        { provide: UrlParamsHelperService, useValue: {} },
        {
          provide: WorkPackagesListService,
          useValue: {
            getCurrentQueryProps: (params:{ query_props?:string|null }) => (
              params.query_props ? decodeURIComponent(params.query_props) : null
            ),
          },
        },
      ],
    });

    listener = TestBed.inject(QueryParamListenerService);
    checksum = TestBed.inject(WorkPackagesListChecksumService);
    emitted = [];
    listener.observe$.subscribe((value) => emitted.push(value));
  });

  afterEach(() => {
    listener.removeQueryChangeListener();
    window.history.replaceState(null, '', originalUrl);
  });

  it('ignores URL changes while the initial load has not seeded the checksum', () => {
    navigateTo(`?query_id=2&query_props=${encodeURIComponent(cardsProps)}`);

    expect(emitted).toEqual([]);
  });

  it('reloads for URL changes once the checksum is seeded', () => {
    checksum.set('1', splitCardsProps);

    navigateTo(`?query_id=1&query_props=${encodeURIComponent(cardsProps)}`);

    expect(emitted).toEqual([cardsProps]);
  });

  describe('reconciling with the URL after the initial load', () => {
    it('reloads for a URL change that was ignored during the initial load', () => {
      navigateTo(`?query_id=2&query_props=${encodeURIComponent(cardsProps)}`);
      checksum.set('1', splitCardsProps);

      listener.reconcileWithUrl();

      expect(emitted).toEqual([cardsProps]);
      expect({ id: checksum.id, checksum: checksum.checksum }).toEqual({ id: '2', checksum: cardsProps });
    });

    it('does not reload when the URL still matches the initial load', () => {
      window.history.replaceState(null, '', `${window.location.pathname}?query_id=1&query_props=${encodeURIComponent(cardsProps)}`);
      checksum.set('1', cardsProps);

      listener.reconcileWithUrl();

      expect(emitted).toEqual([]);
    });

    it('does not reload a default query loaded without URL params', () => {
      checksum.set(null, splitCardsProps);

      listener.reconcileWithUrl();

      expect(emitted).toEqual([]);
    });

    it('reloads when the initial load failed before seeding the checksum', () => {
      listener.reconcileWithUrl();

      expect(emitted).toEqual([null]);
    });
  });
});

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

import { NO_ERRORS_SCHEMA } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { provideHttpClient, withInterceptorsFromDi, withXhr } from '@angular/common/http';
import { provideHttpClientTesting } from '@angular/common/http/testing';
import { NgSelectModule } from '@ng-select/ng-select';
import { firstValueFrom, Observable } from 'rxjs';
import { States } from 'core-app/core/states/states.service';

import { ProjectAutocompleterComponent } from './project-autocompleter.component';
import { IProjectAutocompleteItem } from './project-autocomplete-item';

interface MatchingItemsAccess {
  matchingItems(elements:IProjectAutocompleteItem[], matching:string):Observable<IProjectAutocompleteItem[]>;
}

describe('ProjectAutocompleterComponent', () => {
  let component:ProjectAutocompleterComponent;

  const project = (overrides:Partial<IProjectAutocompleteItem>):IProjectAutocompleteItem => ({
    id: 1,
    href: '/api/v3/projects/1',
    name: 'Project',
    disabled: false,
    ancestors: [],
    ...overrides,
  });

  const elements:IProjectAutocompleteItem[] = [
    project({ id: 1, href: '/api/v3/projects/1', name: 'Foo Project', identifier: 'foo-project' }),
    project({ id: 2, href: '/api/v3/projects/2', name: 'Bar Project', identifier: 'special-id' }),
  ];

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      declarations: [ProjectAutocompleterComponent],
      schemas: [NO_ERRORS_SCHEMA],
      imports: [NgSelectModule],
      providers: [States, provideHttpClient(withXhr(), withInterceptorsFromDi()), provideHttpClientTesting()],
    }).compileComponents();

    component = TestBed.createComponent(ProjectAutocompleterComponent).componentInstance;
  });

  function matchingItems(
    matching:string,
    items:IProjectAutocompleteItem[] = elements,
  ):Promise<IProjectAutocompleteItem[]> {
    return firstValueFrom((component as unknown as MatchingItemsAccess).matchingItems(items, matching));
  }

  it('returns every element when there is no search term', async () => {
    expect(await matchingItems('')).toEqual(elements);
  });

  it('matches by name', async () => {
    expect(await matchingItems('foo')).toEqual([elements[0]]);
  });

  it('matches by identifier even when the name does not match', async () => {
    expect(await matchingItems('special-id')).toEqual([elements[1]]);
  });

  it('matches case-insensitively on identifier', async () => {
    expect(await matchingItems('SPECIAL-ID')).toEqual([elements[1]]);
  });

  it('returns nothing when neither name nor identifier match', async () => {
    expect(await matchingItems('nonexistent')).toEqual([]);
  });

  it('does not throw for an element without an identifier', async () => {
    const noIdentifier = [project({ id: 3, href: '/api/v3/projects/3', name: 'No Identifier Project' })];

    await expect(matchingItems('zzz', noIdentifier)).resolves.toEqual([]);
  });
});

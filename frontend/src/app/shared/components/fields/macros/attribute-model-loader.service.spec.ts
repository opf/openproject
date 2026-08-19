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
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { TestBed } from '@angular/core/testing';
import { firstValueFrom, of } from 'rxjs';
import { type Mock, vi } from 'vitest';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { TransitionService } from '@uirouter/core';
import { CurrentProjectService } from 'core-app/core/current-project/current-project.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { AttributeModelLoaderService } from 'core-app/shared/components/fields/macros/attribute-model-loader.service';

describe('AttributeModelLoaderService', () => {
  let service:AttributeModelLoaderService;
  let idSpy:Mock;
  let filterSpy:Mock;
  let withOptionalProjectSpy:Mock;

  const wpResource = { id: '42' } as unknown as HalResource;

  beforeEach(async () => {
    idSpy = vi.fn().mockReturnValue({ get: () => of(wpResource) });

    filterSpy = vi.fn().mockReturnValue({ get: () => of({ elements: [wpResource] }) });
    withOptionalProjectSpy = vi
      .fn()
      .mockReturnValue({ work_packages: { filterByTypeaheadOrId: filterSpy } });

    const apiV3Stub = {
      work_packages: { id: idSpy },
      withOptionalProject: withOptionalProjectSpy,
    };

    await TestBed.configureTestingModule({
      providers: [
        AttributeModelLoaderService,
        { provide: ApiV3Service, useValue: apiV3Stub },
        { provide: TransitionService, useValue: { onStart: vi.fn() } },
        { provide: CurrentProjectService, useValue: { id: 'demo-project' } },
        { provide: I18nService, useValue: { t: (key:string) => key } },
      ],
    }).compileComponents();

    service = TestBed.inject(AttributeModelLoaderService);
  });

  it('resolves a numeric id directly via the show endpoint', async () => {
    await firstValueFrom(service.require('workPackage', '42'));

    expect(idSpy).toHaveBeenCalledWith('42');
    expect(filterSpy).not.toHaveBeenCalled();
  });

  it('resolves a semantic identifier directly via the show endpoint', async () => {
    await firstValueFrom(service.require('workPackage', 'OP-19273'));

    expect(idSpy).toHaveBeenCalledWith('OP-19273');
    expect(withOptionalProjectSpy).not.toHaveBeenCalled();
  });

  it('routes a zero or zero-padded id through the show endpoint rather than a subject search', async () => {
    await firstValueFrom(service.require('workPackage', '0'));

    expect(idSpy).toHaveBeenCalledWith('0');
    expect(filterSpy).not.toHaveBeenCalled();

    idSpy.mockClear();

    await firstValueFrom(service.require('workPackage', '007'));

    expect(idSpy).toHaveBeenCalledWith('007');
    expect(filterSpy).not.toHaveBeenCalled();
  });

  it('resolves a free-text subject reference via the typeahead filter', async () => {
    await firstValueFrom(service.require('workPackage', 'Project start'));

    expect(filterSpy).toHaveBeenCalledWith('Project start', false, { pageSize: '1' });
    expect(idSpy).not.toHaveBeenCalled();
  });
});

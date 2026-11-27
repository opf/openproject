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
import { firstValueFrom, of } from 'rxjs';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { CurrentProjectService } from 'core-app/core/current-project/current-project.service';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { BoardService } from 'core-app/features/boards/board/board.service';
import { BoardActionsRegistryService } from 'core-app/features/boards/board/board-actions/board-actions-registry.service';
import { HalResourceNotificationService } from 'core-app/features/hal/services/hal-resource-notification.service';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { OpModalLocalsToken } from 'core-app/shared/components/modal/modal.service';
import { OpAutocompleterComponent } from 'core-app/shared/components/autocompleter/op-autocompleter/op-autocompleter.component';
import { AddListModalComponent } from './add-list-modal.component';

describe('AddListModalComponent', () => {
  const unassigned = { id: null, href: null, name: 'none' } as unknown as HalResource;
  const user = Object.create(HalResource.prototype) as HalResource;

  function createModal() {
    TestBed.overrideComponent(AddListModalComponent, { set: { template: '' } });
    TestBed.configureTestingModule({
      declarations: [AddListModalComponent],
      providers: [
        { provide: I18nService, useValue: { t: (key:string) => key } },
        { provide: ApiV3Service, useValue: {} },
        { provide: CurrentProjectService, useValue: {} },
        { provide: PathHelperService, useValue: {} },
        { provide: BoardService, useValue: {} },
        { provide: HalResourceNotificationService, useValue: {} },
        {
          provide: BoardActionsRegistryService,
          useValue: {
            get: () => ({
              resourceName: 'assignee',
              loadAvailable: () => of([unassigned, user]),
              warningTextWhenNoOptionsAvailable: () => Promise.resolve(''),
            }),
          },
        },
        { provide: OpModalLocalsToken, useValue: { board: { actionAttribute: 'assignee' }, active: [] } },
      ],
    });

    const modal = TestBed.createComponent(AddListModalComponent).componentInstance;
    modal.ngSelectComponent = {
      ngSelectInstance: { searchTerm: undefined },
      repositionDropdown: vi.fn(),
    } as unknown as OpAutocompleterComponent;
    modal.ngOnInit();
    return modal;
  }

  it('selects the unassigned option the action offers', async () => {
    const modal = createModal();
    await firstValueFrom(modal.getAutocompleterData(''));

    modal.onModelChange(unassigned);

    expect(modal.selectedAttribute).toBe(unassigned);
  });

  it('selects an offered resource and clears the selection', async () => {
    const modal = createModal();
    await firstValueFrom(modal.getAutocompleterData(''));

    modal.onModelChange(user);
    expect(modal.selectedAttribute).toBe(user);

    modal.onModelChange(undefined);
    expect(modal.selectedAttribute).toBeUndefined();
  });

  it('ignores a value that was not offered', async () => {
    const modal = createModal();
    await firstValueFrom(modal.getAutocompleterData(''));

    modal.onModelChange({ id: 9, name: 'Unrelated' });

    expect(modal.selectedAttribute).toBeUndefined();
  });
});

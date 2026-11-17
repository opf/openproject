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
import { AsyncPipe, NgClass, NgStyle, NgTemplateOutlet } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { provideHttpClient } from '@angular/common/http';
import { firstValueFrom, of, Subject } from 'rxjs';
import { NgSelectModule } from '@ng-select/ng-select';
import { fireEvent, screen, waitFor } from '@testing-library/dom';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { CurrentProjectService } from 'core-app/core/current-project/current-project.service';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { BoardService } from 'core-app/features/boards/board/board.service';
import { BoardActionsRegistryService } from 'core-app/features/boards/board/board-actions/board-actions-registry.service';
import { HalResourceNotificationService } from 'core-app/features/hal/services/hal-resource-notification.service';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { OpModalLocalsToken, OpModalService } from 'core-app/shared/components/modal/modal.service';
import { OpAutocompleterComponent } from 'core-app/shared/components/autocompleter/op-autocompleter/op-autocompleter.component';
import { States } from 'core-app/core/states/states.service';
import { SchemaCacheService } from 'core-app/core/schemas/schema-cache.service';
import { VersionResource } from 'core-app/features/hal/resources/version-resource';
import { GridResource } from 'core-app/features/hal/resources/grid-resource';
import { HalResourceService } from 'core-app/features/hal/services/hal-resource.service';
import { OpIconComponent } from 'core-app/shared/components/icon/icon.component';
import { OpAutocompleterFooterTemplateDirective } from 'core-app/shared/components/autocompleter/autocompleter-footer-template/op-autocompleter-footer-template.directive';
import { AddListModalComponent } from './add-list-modal.component';
import { Board } from '../board';
import { BoardActionService } from '../board-actions/board-action.service';
import { BoardStatusActionService } from '../board-actions/status/status-action.service';
import { BoardVersionActionService } from '../board-actions/version/version-action.service';

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

describe('AddListModalComponent rendering', () => {
  let board:Board;
  let action:BoardActionService;
  let close:ReturnType<typeof vi.fn<OpModalService['close']>>;
  let save:ReturnType<typeof vi.fn<BoardService['save']>>;
  let saveResponse:Subject<Board>;

  beforeEach(async () => {
    close = vi.fn<OpModalService['close']>();
    saveResponse = new Subject<Board>();
    save = vi.fn<BoardService['save']>().mockReturnValue(saveResponse);

    await TestBed.configureTestingModule({
      declarations: [OpAutocompleterComponent, OpAutocompleterFooterTemplateDirective, OpIconComponent, AddListModalComponent],
      imports: [AsyncPipe, NgClass, NgStyle, NgTemplateOutlet, FormsModule, NgSelectModule],
      providers: [
        provideHttpClient(),
        States,
        BoardStatusActionService,
        BoardVersionActionService,
        { provide: CurrentProjectService, useValue: { id: '42' } },
        { provide: SchemaCacheService, useValue: {} },
        { provide: HalResourceNotificationService, useValue: { handleRawError: vi.fn<HalResourceNotificationService['handleRawError']>() } },
        { provide: I18nService, useValue: { t: (key:string) => key } },
        { provide: BoardService, useValue: { save } },
        { provide: OpModalLocalsToken, useFactory: () => ({ board, active: ['1'], service: { close } }) },
      ],
    }).compileComponents();

    const grid = TestBed.inject(HalResourceService).createHalResourceOfClass(GridResource, {
      options: { type: 'action', attribute: 'status' },
      widgets: [],
      _links: { self: { href: '/api/v3/grids/1' } },
    });
    board = new Board(grid);
    action = TestBed.inject(BoardStatusActionService);
    TestBed.inject(BoardActionsRegistryService).add('status', action);
  });

  it('renders a deferred no-options warning for the current search', async () => {
    const response = new Subject<[]>();
    const load = vi.spyOn(action, 'loadAvailable').mockImplementation((_active, search) => search ? response : of([]));
    const warning = new Subject<string>();
    const warningText = vi.spyOn(action, 'warningTextWhenNoOptionsAvailable')
      .mockImplementation((searched) => searched ? firstValueFrom(warning) : Promise.resolve(undefined));

    const fixture = TestBed.createComponent(AddListModalComponent);
    await fixture.whenStable();
    expect(screen.getByText('js.boards.add_list')).toBeVisible();
    expect(screen.getByRole('button', { name: 'js.button_add' })).toBeDisabled();

    const input = screen.getByRole('combobox');
    await waitFor(() => expect(input).toHaveAttribute('aria-expanded', 'true'));
    fireEvent.input(input, { target: { value: '#unknown' } });
    await waitFor(() => expect(load).toHaveBeenCalledWith(new Set(['1']), 'unknown'));
    response.next([]);
    await waitFor(() => expect(warningText).toHaveBeenCalledWith(true));
    await fixture.whenStable();
    expect(screen.queryByText('No available statuses')).toBeNull();

    warning.next('No available statuses');
    expect(await screen.findByText('No available statuses')).toBeVisible();

  });

  it('enables Add after an async save fails', async () => {
    const status = TestBed.inject(HalResourceService).createHalResource({
      name: 'New status',
      _links: { self: { href: '/api/v3/statuses/2' } },
    });
    vi.spyOn(action, 'loadAvailable').mockReturnValue(of([status]));
    const addColumn = vi.spyOn(action, 'addColumnWithActionAttribute').mockResolvedValue(board);

    const fixture = TestBed.createComponent(AddListModalComponent);
    await fixture.whenStable();
    const add = screen.getByRole('button', { name: 'js.button_add' });

    fireEvent.click(await screen.findByText('New status'));
    await fixture.whenStable();
    expect(add).toBeEnabled();

    fireEvent.click(add);
    await waitFor(() => expect(save).toHaveBeenCalledWith(board));
    expect(add).toBeDisabled();
    expect(addColumn).toHaveBeenCalledWith(board, status);

    saveResponse.error(new Error('Could not save board'));
    await waitFor(() => expect(add).toBeEnabled());
    expect(close).not.toHaveBeenCalled();
  });

  it('uses the typed version name and the version returned by the API', async () => {
    board.grid.options.attribute = 'version';
    const versionAction = TestBed.inject(BoardVersionActionService);
    TestBed.inject(BoardActionsRegistryService).add('version', versionAction);
    const load = vi.spyOn(versionAction, 'loadAvailable').mockReturnValue(of([]));
    const addColumn = vi.spyOn(versionAction, 'addColumnWithActionAttribute').mockResolvedValue(board);
    const version = TestBed.inject(HalResourceService).createHalResourceOfClass(VersionResource, {
      name: 'New version',
      _links: { self: { href: '/api/v3/versions/7' } },
    });
    const versionResponse = new Subject<VersionResource>();
    const postVersion = vi.spyOn(TestBed.inject(ApiV3Service).versions, 'post').mockReturnValue(versionResponse);

    const fixture = TestBed.createComponent(AddListModalComponent);
    await fixture.whenStable();
    const input = screen.getByRole('combobox');
    await waitFor(() => expect(load).toHaveBeenCalledWith(new Set(['1']), ''));
    await waitFor(() => expect(input).toHaveAttribute('aria-expanded', 'true'));
    fireEvent.input(input, { target: { value: 'New version' } });
    fireEvent.click(await screen.findByRole('button', { name: 'js.button_create New version' }));
    expect(postVersion).toHaveBeenCalledWith({
      name: 'New version',
      _links: { definingProject: { href: '/api/v3/projects/42' } },
    });
    expect(addColumn).not.toHaveBeenCalled();

    versionResponse.next(version);
    versionResponse.complete();
    await waitFor(() => expect(save).toHaveBeenCalledWith(board));
    expect(addColumn).toHaveBeenCalledWith(board, version);
    expect(screen.getByRole('button', { name: 'js.button_add' })).toBeDisabled();
    saveResponse.error(new Error('Could not save board'));
    await waitFor(() => expect(screen.getByRole('button', { name: 'js.button_add' })).toBeEnabled());
  });
});

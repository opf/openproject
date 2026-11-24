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

import '@openproject/primer-view-components/app/components/primer/alpha/action_menu/action_menu_element.js';
import { Component, CUSTOM_ELEMENTS_SCHEMA } from '@angular/core';
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { screen, waitFor, within } from '@testing-library/dom';
import { type Mock } from 'vitest';
import { userEvent } from 'vitest/browser';
import { OpActionMenuComponent } from 'core-app/shared/components/op-context-menu/action-menu/op-action-menu.component';
import {
  OpActionMenuTriggerDirective,
} from 'core-app/shared/components/op-context-menu/action-menu/op-action-menu-trigger.directive';
import { BcfViewService, BcfViewState } from 'core-app/features/bim/ifc_models/pages/viewer/bcf-view.service';
import { ViewerBridgeService } from 'core-app/features/bim/bcf/bcf-viewer-bridge/viewer-bridge.service';
import { WorkPackageFiltersService } from 'core-app/features/work-packages/components/filters/wp-filters/wp-filters.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { BcfViewToggleDropdownDirective } from './bcf-view-toggle-dropdown.directive';

@Component({
  imports: [OpActionMenuComponent, OpActionMenuTriggerDirective, BcfViewToggleDropdownDirective],
  schemas: [CUSTOM_ELEMENTS_SCHEMA],
  template: `
    <op-action-menu opBcfViewDropdown label="Select view">
      <button opActionMenuTrigger type="button">Trigger</button>
    </op-action-menu>
  `,
})
class HostComponent {}

describe('BcfViewToggleDropdownDirective', () => {
  let fixture:ComponentFixture<HostComponent>;
  let shouldShowViewer:boolean;
  let current:BcfViewState;
  let filtersVisible:boolean;
  let update:Mock<BcfViewService['update']>;
  let toggleVisibility:Mock<WorkPackageFiltersService['toggleVisibility']>;

  const text:Record<BcfViewState, string> = {
    cards: 'Cards',
    viewer: 'Viewer',
    splitTable: 'Viewer and table',
    splitCards: 'Viewer and cards',
    table: 'Table',
  };

  const setup = async () => {
    update = vi.fn<BcfViewService['update']>();
    toggleVisibility = vi.fn<WorkPackageFiltersService['toggleVisibility']>();
    await TestBed.configureTestingModule({
      imports: [HostComponent],
      providers: [
        { provide: I18nService, useValue: { t: (key:string) => key } },
        {
          provide: ViewerBridgeService,
          useValue: { get shouldShowViewer() { return shouldShowViewer; } },
        },
        {
          provide: BcfViewService,
          useValue: {
            text,
            icon: {},
            update,
            currentViewerState: () => current,
          } satisfies Partial<BcfViewService>,
        },
        {
          provide: WorkPackageFiltersService,
          useValue: { get visible() { return filtersVisible; }, toggleVisibility } satisfies Partial<WorkPackageFiltersService>,
        },
      ],
    }).compileComponents();
    fixture = TestBed.createComponent(HostComponent);
    await fixture.whenStable();
  };

  const openMenu = async () => {
    await userEvent.click(screen.getByRole('button', { name: 'Trigger' }));
    return screen.findByRole('menu', { name: 'Select view' });
  };

  beforeEach(() => {
    shouldShowViewer = true;
    current = 'splitCards';
    filtersVisible = true;
  });

  afterEach(() => fixture.destroy());

  it('lists all views with the current one selected when a viewer is available', async () => {
    await setup();
    const menu = await openMenu();

    const items = within(menu).getAllByRole('menuitemradio');
    expect(items).toHaveLength(5);
    ['Viewer', 'Cards', 'Viewer and cards', 'Viewer and table', 'Table']
      .forEach((name, index) => expect(items[index]).toHaveAccessibleName(name));
    expect(within(menu).getByRole('menuitemradio', { checked: true })).toHaveAccessibleName('Viewer and cards');
  });

  it('lists only cards and table without a viewer', async () => {
    shouldShowViewer = false;
    current = 'cards';
    await setup();
    const menu = await openMenu();

    const items = within(menu).getAllByRole('menuitemradio');
    expect(items).toHaveLength(2);
    ['Cards', 'Table'].forEach((name, index) => expect(items[index]).toHaveAccessibleName(name));
    expect(within(menu).getByRole('menuitemradio', { checked: true })).toHaveAccessibleName('Cards');
  });

  it('switches view and closes the filters when another view is chosen', async () => {
    await setup();
    const menu = await openMenu();

    await userEvent.click(within(menu).getByRole('menuitemradio', { name: 'Table' }));

    expect(update).toHaveBeenCalledWith('table');
    expect(toggleVisibility).toHaveBeenCalledTimes(1);
  });

  it('does nothing when the current view is chosen', async () => {
    await setup();
    const menu = await openMenu();

    await userEvent.click(within(menu).getByRole('menuitemradio', { name: 'Viewer and cards' }));

    await waitFor(() => expect(screen.queryByRole('menu', { name: 'Select view' })).not.toBeInTheDocument());
    expect(update).not.toHaveBeenCalled();
    expect(toggleVisibility).not.toHaveBeenCalled();
  });

  it('can be operated with the keyboard', async () => {
    await setup();
    screen.getByRole('button', { name: 'Trigger' }).focus();
    await userEvent.keyboard('{Enter}');
    const menu = await screen.findByRole('menu', { name: 'Select view' });
    await waitFor(() => expect(within(menu).getAllByRole('menuitemradio')[0]).toHaveFocus());
    await userEvent.keyboard('{ArrowDown}');

    expect(within(menu).getByRole('menuitemradio', { name: 'Cards' })).toHaveFocus();

    await userEvent.keyboard('{Enter}');

    expect(update).toHaveBeenCalledExactlyOnceWith('cards');
  });
});

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
import { Component } from '@angular/core';
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { screen, waitFor, within } from '@testing-library/dom';
import { userEvent } from 'vitest/browser';
import { of } from 'rxjs';
import { settlePopover } from 'core-common/testing/timing';
import { DeviceService } from 'core-app/core/browser/device.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { AuthorisationService } from 'core-app/core/model-auth/model-auth.service';
import { States } from 'core-app/core/states/states.service';
import { TurboRequestsService } from 'core-app/core/turbo/turbo-requests.service';
import { WorkPackagesListService } from 'core-app/features/work-packages/components/wp-list/wp-list.service';
import { UrlParamsHelperService } from 'core-app/features/work-packages/components/wp-query/url-params-helper';
import { IsolatedQuerySpace } from 'core-app/features/work-packages/directives/query-space/isolated-query-space';
import {
  WorkPackageViewColumnsService,
} from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-columns.service';
import { OpModalService } from 'core-app/shared/components/modal/modal.service';
import { StaticQueriesService } from 'core-app/shared/components/op-view-select/op-static-queries.service';
import { OpActionMenuComponent } from 'core-app/shared/components/op-context-menu/action-menu/op-action-menu.component';
import {
  OpActionMenuTriggerDirective,
} from 'core-app/shared/components/op-context-menu/action-menu/op-action-menu-trigger.directive';
import { OpSettingsMenuDirective } from './op-settings-dropdown-menu.directive';

@Component({
  imports: [OpActionMenuComponent, OpActionMenuTriggerDirective, OpSettingsMenuDirective],
  template: `
    <op-action-menu opSettingsContextMenu
      align="end"
      label="More actions"
      [hideTableOptions]="hideTableOptions"
      [showCalendarSharingOption]="showCalendarSharingOption">
      <button opActionMenuTrigger type="button">Settings</button>
    </op-action-menu>
  `,
})
class HostComponent {
  hideTableOptions = false;

  showCalendarSharingOption = false;
}

describe('OpSettingsMenuDirective', () => {
  let fixture:ComponentFixture<HostComponent>;
  let show:ReturnType<typeof vi.fn>;
  let query:Record<string, unknown>;
  let form:Record<string, unknown>;
  let device:{ isMobile:boolean };

  const settle = settlePopover;
  const openMenu = async () => {
    await userEvent.click(screen.getByRole('button', { name: 'Settings' }));
    await fixture.whenStable();
    await settle();
    return screen.findByRole('menu', { name: 'More actions' });
  };
  const names = (menu:HTMLElement) => within(menu)
    .getAllByRole('menuitem')
    .map((item) => item.textContent?.trim());
  const outline = (menu:HTMLElement) => Array.from(menu.children)
    .map((row) => (row.getAttribute('role') === 'separator' ? '---' : row.textContent?.trim()));

  const createHost = async (hosted:Partial<HostComponent> = {}) => {
    fixture = TestBed.createComponent(HostComponent);
    Object.assign(fixture.componentInstance, hosted);
    await fixture.whenStable();
  };

  beforeEach(async () => {
    window.I18n.store({
      en: {
        js: {
          toolbar: {
            settings: {
              configure_view: 'Configure view',
              sort_by: 'Sort by',
              group_by: 'Group by',
              page_settings: 'Rename view',
              save: 'Save',
              save_as: 'Save as',
              delete: 'Delete',
              share_calendar: 'Subscribe to calendar',
              export: 'Export',
              visibility_settings: 'Visibility settings',
            },
          },
          work_packages: { query: { add_columns: 'Add columns' } },
        },
      },
    });
    show = vi.fn();
    query = { results: {} };
    form = { $links: { create_new: { href: '/create' } } };
    device = { isMobile: false };

    await TestBed.configureTestingModule({
      imports: [HostComponent],
      providers: [
        { provide: I18nService, useValue: { t: (key:string) => window.I18n.t(key) } },
        { provide: AuthorisationService, useValue: { can: () => true, cannot: () => false } },
        { provide: OpModalService, useValue: { show } },
        { provide: DeviceService, useValue: device },
        { provide: WorkPackagesListService, useValue: {} },
        { provide: States, useValue: {} },
        { provide: WorkPackageViewColumnsService, useValue: {} },
        { provide: UrlParamsHelperService, useValue: {} },
        { provide: StaticQueriesService, useValue: {} },
        { provide: TurboRequestsService, useValue: {} },
        {
          provide: IsolatedQuerySpace,
          useValue: {
            query: { values$: () => of(query), value: query },
            queryForm: { valuesPromise: () => Promise.resolve(form), values$: () => of(form) },
          },
        },
      ],
    }).compileComponents();
  });

  afterEach(() => fixture.destroy());

  it('lists the view actions in order, with Octicons and no Spot icons', async () => {
    await createHost();
    const menu = await openMenu();

    expect(outline(menu)).toEqual([
      'Configure view',
      'Rename view',
      'Add columns',
      'Visibility settings',
      '---',
      'Sort by',
      'Group by',
      '---',
      'Save',
      'Save as',
      'Export',
      '---',
      'Delete',
    ]);
    within(menu).getAllByRole('menuitem').forEach((item) => expect(item.querySelector('svg')).not.toBeNull());
    expect(within(menu).getByRole('menuitem', { name: 'Configure view' }).querySelector('svg')).toHaveClass('octicon-gear');
    expect(within(menu).getByRole('menuitem', { name: 'Delete' }).querySelector('svg')).toHaveClass('octicon-trash');
    expect(menu.querySelector('.op-icon, [class^="icon-"], [class*=" icon-"]')).toBeNull();
  });

  it('sets Delete apart as the last, dangerous action', async () => {
    await createHost();
    const menu = await openMenu();

    const item = within(menu).getAllByRole('menuitem').at(-1)!;
    const row = item.closest('li')!;
    expect(item).toHaveAccessibleName('Delete');
    expect(row).toHaveClass('ActionListItem--danger');
    expect(row.previousElementSibling).toHaveAttribute('role', 'separator');
  });

  it('disables renaming while the view is unsaved', async () => {
    await createHost();
    const menu = await openMenu();

    expect(within(menu).getByRole('menuitem', { name: 'Rename view' })).toHaveAttribute('aria-disabled', 'true');
    expect(within(menu).getByRole('menuitem', { name: 'Save as' })).not.toHaveAttribute('aria-disabled', 'true');
  });

  it('enables renaming a saved view', async () => {
    query = { id: '5', results: {} };
    await createHost();
    const menu = await openMenu();

    expect(within(menu).getByRole('menuitem', { name: 'Rename view' })).not.toHaveAttribute('aria-disabled', 'true');
  });

  it('leaves out the table options when they are hidden', async () => {
    await createHost({ hideTableOptions: true });
    const menu = await openMenu();

    expect(outline(menu)).toEqual(['Rename view', 'Visibility settings', '---', 'Save', 'Save as', '---', 'Delete']);
  });

  it('leaves out the column and grouping actions on a mobile screen, keeping the arrow keys moving', async () => {
    device.isMobile = true;
    await createHost();
    screen.getByRole('button', { name: 'Settings' }).focus();
    await userEvent.keyboard('{Enter}');
    await fixture.whenStable();
    await settle();
    const menu = await screen.findByRole('menu', { name: 'More actions' });

    expect(names(menu)).toEqual(['Configure view', 'Rename view', 'Visibility settings', 'Sort by', 'Save', 'Save as', 'Export', 'Delete']);
    await waitFor(() => expect(within(menu).getByRole('menuitem', { name: 'Configure view' })).toHaveFocus());
    await userEvent.keyboard('{ArrowDown}');
    expect(within(menu).getByRole('menuitem', { name: 'Rename view' })).toHaveFocus();
  });

  it('offers calendar subscription only when asked to', async () => {
    await createHost({ showCalendarSharingOption: true });
    const menu = await openMenu();

    expect(outline(menu).slice(-6)).toEqual(['Save', 'Save as', 'Subscribe to calendar', 'Export', '---', 'Delete']);
    expect(within(menu).getByRole('menuitem', { name: 'Subscribe to calendar' }).querySelector('svg')).not.toBeNull();
  });

  it('opens the table configuration on the chosen tab', async () => {
    await createHost();
    const menu = await openMenu();

    await userEvent.click(within(menu).getByRole('menuitem', { name: 'Sort by' }));

    expect(show).toHaveBeenCalledTimes(1);
    expect(show.mock.calls[0][2]).toEqual({ initialTab: 'sort-by' });
  });

  describe('with custom fields', () => {
    beforeEach(() => {
      query = { results: { customFields: { href: '/projects/demo/settings/custom_fields', name: 'Custom fields' } } };
      form = { $links: { create_new: { href: '/create' } }, configureForm: { href: '/configure' } };
    });

    it('puts the settings link between separators, ahead of Delete', async () => {
      await createHost();
      const menu = await openMenu();

      const items = within(menu).getAllByRole('menuitem', { hidden: true });
      const link = items.at(-2)!;
      const row = link.closest('li')!;
      expect(items.at(-1)).toHaveAccessibleName('Delete');
      expect(row.previousElementSibling).toHaveAttribute('role', 'separator');
      expect(row.nextElementSibling).toHaveAttribute('role', 'separator');
      expect(link).toHaveAccessibleName('Custom fields');
      expect(link).toHaveAttribute('href', '/projects/demo/settings/custom_fields');
      expect(link.querySelector('svg')).not.toBeNull();
    });

    it('omits the link when the table options are hidden', async () => {
      await createHost({ hideTableOptions: true });
      const menu = await openMenu();

      expect(within(menu).queryByRole('menuitem', { name: 'Custom fields' })).toBeNull();
    });
  });
});

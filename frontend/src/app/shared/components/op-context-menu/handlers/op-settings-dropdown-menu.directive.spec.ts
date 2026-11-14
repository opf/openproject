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
import { screen, within } from '@testing-library/dom';
import { userEvent } from 'vitest/browser';
import { of } from 'rxjs';
import { settlePopover } from 'core-common/testing/timing';
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

  const settle = settlePopover;
  const openMenu = async () => {
    await userEvent.click(screen.getByRole('button', { name: 'Settings' }));
    await fixture.whenStable();
    await settle();
    return screen.findByRole('menu', { name: 'More actions' });
  };
  // Add columns and Group by are `hidden-for-mobile`, which the narrow test viewport applies.
  const names = (menu:HTMLElement) => within(menu)
    .getAllByRole('menuitem', { hidden: true })
    .map((item) => item.textContent?.trim());

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

    await TestBed.configureTestingModule({
      imports: [HostComponent],
      providers: [
        { provide: I18nService, useValue: { t: (key:string) => window.I18n.t(key) } },
        { provide: AuthorisationService, useValue: { can: () => true, cannot: () => false } },
        { provide: OpModalService, useValue: { show } },
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

    expect(names(menu)).toEqual([
      'Configure view',
      'Add columns',
      'Sort by',
      'Group by',
      'Rename view',
      'Save',
      'Save as',
      'Delete',
      'Export',
      'Visibility settings',
    ]);
    within(menu).getAllByRole('menuitem', { hidden: true }).forEach((item) => expect(item.querySelector('svg')).not.toBeNull());
    expect(within(menu).getByRole('menuitem', { name: 'Configure view' }).querySelector('svg')).toHaveClass('octicon-gear');
    expect(within(menu).getByRole('menuitem', { name: 'Delete' }).querySelector('svg')).toHaveClass('octicon-trash');
    expect(menu.querySelector('.op-icon, [class^="icon-"], [class*=" icon-"]')).toBeNull();
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

    expect(names(menu)).toEqual(['Rename view', 'Save', 'Save as', 'Delete', 'Visibility settings']);
  });

  it('offers calendar subscription only when asked to', async () => {
    await createHost({ showCalendarSharingOption: true });
    const menu = await openMenu();

    expect(names(menu)).toContain('Subscribe to calendar');
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

    it('ends with a separator and the settings link', async () => {
      await createHost();
      const menu = await openMenu();

      const items = within(menu).getAllByRole('menuitem', { hidden: true });
      const link = items.at(-1)!;
      const separator = within(menu).getByRole('separator', { hidden: true });
      expect(items.at(-2)!.compareDocumentPosition(separator) & Node.DOCUMENT_POSITION_FOLLOWING).toBeTruthy();
      expect(separator.compareDocumentPosition(link) & Node.DOCUMENT_POSITION_FOLLOWING).toBeTruthy();
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

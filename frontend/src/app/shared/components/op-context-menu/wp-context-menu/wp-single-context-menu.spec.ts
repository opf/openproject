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
import { settlePopover } from 'core-common/testing/timing';
import { BehaviorSubject } from 'rxjs';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { AuthorisationService } from 'core-app/core/model-auth/model-auth.service';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { TurboRequestsService } from 'core-app/core/turbo/turbo-requests.service';
import { UrlParamsService } from 'core-app/core/navigation/url-params.service';
import { HookService } from 'core-app/features/plugins/hook-service';
import { CopyToClipboardService } from 'core-app/shared/components/copy-to-clipboard/copy-to-clipboard.service';
import { TimeEntryTimerService } from 'core-app/shared/components/time_entries/services/time-entry-timer.service';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { OpActionMenuComponent } from 'core-app/shared/components/op-context-menu/action-menu/op-action-menu.component';
import {
  OpActionMenuTriggerDirective,
} from 'core-app/shared/components/op-context-menu/action-menu/op-action-menu-trigger.directive';
import type { WorkPackageAction } from 'core-app/features/work-packages/components/wp-table/context-menu-helper/wp-context-menu-helper.service';
import { WorkPackageSingleContextMenuDirective } from './wp-single-context-menu';

@Component({
  imports: [OpActionMenuComponent, OpActionMenuTriggerDirective, WorkPackageSingleContextMenuDirective],
  template: `
    <op-action-menu wpSingleContextMenu [wpSingleContextMenu-workPackage]="workPackage" align="end" label="More">
      <button opActionMenuTrigger type="button">More</button>
    </op-action-menu>
  `,
})
class HostComponent {
  workPackage!:WorkPackageResource;
}

// Mirrors the action modules/resource_management/frontend/module/main.ts registers.
const allocateResourceAction:WorkPackageAction = {
  key: 'allocate_resource',
  icon: 'icon-user-plus',
  link: 'allocateResource',
  turboRequest: true,
  indexBy(actions:WorkPackageAction[]) {
    const index = actions.reduce(
      (last, action, i) => (['log_time', 'start_timer', 'stop_timer', 'log_costs'].includes(action.key) ? i : last),
      -1,
    );
    return index !== -1 ? index + 1 : actions.length;
  },
};

describe('WorkPackageSingleContextMenuDirective', () => {
  let fixture:ComponentFixture<HostComponent>;
  let requestStream:ReturnType<typeof vi.fn>;

  const link = (href:string) => ({ href });
  const workPackage = () => ({
    id: '42',
    displayId: 'PROJ-42',
    $links: {},
    project: { $load: () => Promise.resolve(), identifier: 'proj' },
    logTime: link('/log'),
    delete: link('/delete'),
    pluginLink: link('/plugin'),
    allocateResource: link('/allocate'),
  }) as unknown as WorkPackageResource;

  const settle = settlePopover;
  const openMenu = async () => {
    await userEvent.click(screen.getByRole('button', { name: 'More' }));
    await fixture.whenStable();
    await settle();
    return screen.findByRole('menu', { name: 'More' });
  };

  beforeEach(async () => {
    window.I18n.store({
      en: {
        js: {
          button_copy_link_to_clipboard: 'Copy link to clipboard',
          button_copy_work_package_id: 'Copy work package ID',
          button_log_time: 'Log time',
          button_start_timer: 'Start timer',
          button_delete: 'Delete',
          button_plugin_action: 'Plugin action',
          button_allocate_resource: 'Allocate resource',
        },
      },
    });
    requestStream = vi.fn();
    const hooks = new HookService();
    hooks.register('workPackageSingleContextMenu', () => ({ key: 'plugin_action', icon: 'icon-unknown-plugin', link: 'pluginLink' }));
    hooks.register('workPackageSingleContextMenu', () => allocateResourceAction);

    await TestBed.configureTestingModule({
      imports: [HostComponent],
      providers: [
        { provide: HookService, useValue: hooks },
        { provide: I18nService, useValue: { t: (key:string) => window.I18n.t(key) } },
        { provide: TurboRequestsService, useValue: { requestStream, request: vi.fn() } },
        { provide: ApiV3Service, useValue: {} },
        { provide: AuthorisationService, useValue: { initModelAuth: vi.fn() } },
        { provide: PathHelperService, useValue: { workPackageShortPath: (id:string) => `/wp/${id}`, timeEntryWorkPackageDialog: () => '/log', staticBase: '' } },
        { provide: UrlParamsService, useValue: {} },
        { provide: CopyToClipboardService, useValue: { copy: vi.fn() } },
        { provide: TimeEntryTimerService, useValue: { activeTimer$: new BehaviorSubject(null) } },
      ],
    }).compileComponents();

    fixture = TestBed.createComponent(HostComponent);
    fixture.componentInstance.workPackage = workPackage();
    await fixture.whenStable();
  });

  afterEach(() => fixture.destroy());

  it('renders Octicons for mapped actions and none for unmapped plugin icons', async () => {
    const menu = await openMenu();

    expect(within(menu).getByRole('menuitem', { name: /Copy work package ID/ }).querySelector('svg')).not.toBeNull();
    expect(within(menu).getByRole('menuitem', { name: /Delete/ }).querySelector('svg')).not.toBeNull();
    expect(menu.querySelector('.op-icon, [class^="icon-"], [class*=" icon-"]')).toBeNull();
    expect(within(menu).getByRole('menuitem', { name: 'Plugin action' }).querySelector('svg')).toBeNull();
  });

  it('places the plugin allocation item after the time items where indexBy puts it', async () => {
    const menu = await openMenu();

    const names = within(menu).getAllByRole('menuitem').map((item) => item.textContent?.trim());

    expect(names.slice(names.indexOf('Log time'), names.indexOf('Log time') + 3))
      .toEqual(['Log time', 'Start timer', 'Allocate resource']);
    expect(names.indexOf('Delete')).toBe(names.length - 1);
  });

  it('requests the stream of a turbo action when it is chosen', async () => {
    const menu = await openMenu();

    await userEvent.click(within(menu).getByRole('menuitem', { name: /Allocate resource/ }));
    await settle();

    expect(requestStream).toHaveBeenCalledWith('/allocate');
  });

  it('flags the More button as expanded only while its menu is open', async () => {
    const button = screen.getByRole('button', { name: 'More' });
    expect(button).toHaveAttribute('aria-expanded', 'false');

    const menu = await openMenu();

    await waitFor(() => expect(button).toHaveAttribute('aria-expanded', 'true'));
    await waitFor(() => expect(menu).toContainElement(document.activeElement as HTMLElement));
    await userEvent.keyboard('{Escape}');
    await settle();

    expect(screen.queryByRole('menu', { name: 'More' })).toBeNull();
    expect(button).toHaveAttribute('aria-expanded', 'false');
  });
});

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
import { Component, signal } from '@angular/core';
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { fireEvent, screen, waitFor, within } from '@testing-library/dom';
import { userEvent } from 'vitest/browser';
import { settlePopover } from 'core-common/testing/timing';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import {
  WorkPackageNotificationService,
} from 'core-app/features/work-packages/services/notifications/work-package-notification.service';
import { HalResourceEditingService } from 'core-app/shared/components/fields/edit/services/hal-resource-editing.service';
import { ToastService } from 'core-app/shared/components/toaster/toast.service';
import { OpActionMenuComponent } from 'core-app/shared/components/op-context-menu/action-menu/op-action-menu.component';
import {
  OpActionMenuTriggerDirective,
} from 'core-app/shared/components/op-context-menu/action-menu/op-action-menu-trigger.directive';
import { WorkPackageStatusDropdownDirective } from './wp-status-dropdown-menu.directive';

@Component({
  imports: [OpActionMenuComponent, OpActionMenuTriggerDirective, WorkPackageStatusDropdownDirective],
  template: `
    <op-action-menu wpStatusDropdown [wpStatusDropdown-workPackage]="workPackage" label="Status">
      <button opActionMenuTrigger type="button" [attr.aria-disabled]="notAllowed() || null">Status New</button>
    </op-action-menu>
  `,
})
class HostComponent {
  workPackage = { id: '42' } as WorkPackageResource;

  notAllowed = signal(false);
}

describe('WorkPackageStatusDropdownDirective', () => {
  let fixture:ComponentFixture<HostComponent>;
  let resolveForm:() => void;
  let writable:boolean;
  let getForm:ReturnType<typeof vi.fn>;
  let save:ReturnType<typeof vi.fn>;
  let projectedResource:{ status?:unknown };
  let addError:ReturnType<typeof vi.fn>;
  let showSave:ReturnType<typeof vi.fn>;
  let showError:ReturnType<typeof vi.fn>;

  const settle = settlePopover;
  const button = () => screen.getByRole('button', { name: 'Status New' });
  const menus = () => screen.queryAllByRole('menu', { name: 'Status' });
  const openedMenu = async () => {
    await userEvent.click(button());
    resolveForm();
    await fixture.whenStable();
    await settle();
    return screen.findByRole('menu', { name: 'Status' });
  };

  beforeEach(async () => {
    writable = true;
    projectedResource = {};
    addError = vi.fn();
    showSave = vi.fn();
    showError = vi.fn();
    save = vi.fn(() => Promise.resolve());
    getForm = vi.fn(() => new Promise((resolve) => {
      resolveForm = () => resolve({
        schema: {
          status: {
            allowedValues: [
              { id: '1', name: 'New' },
              { id: '2', name: 'In progress' },
              { id: '3', name: 'Locked', isReadonly: true },
            ],
          },
        },
      });
    }));
    const change = {
      getForm,
      get schema() { return { status: { writable } }; },
      get projectedResource() { return projectedResource; },
    };

    await TestBed.configureTestingModule({
      imports: [HostComponent],
      providers: [
        {
          provide: I18nService,
          useValue: {
            t: (key:string) => ({
              'js.work_packages.message_work_package_read_only': 'Work package is locked',
              'js.work_packages.message_work_package_status_blocked': 'Status is blocked',
            }[key] ?? key),
          },
        },
        { provide: HalResourceEditingService, useValue: { changeFor: () => change, save } },
        { provide: ToastService, useValue: { addError } },
        { provide: WorkPackageNotificationService, useValue: { showSave, showError } },
      ],
    }).compileComponents();

    fixture = TestBed.createComponent(HostComponent);
    await fixture.whenStable();
  });

  afterEach(() => fixture.destroy());

  it('shows a normal status with a highlight dot and no icon', async () => {
    const menu = await openedMenu();

    const item = within(menu).getByRole('menuitem', { name: 'New' });
    expect(item.querySelector('svg')).toBeNull();
    expect(item.querySelector('.__hl_dot')).toHaveClass('__hl_status_1');
    const dot = getComputedStyle(item.querySelector('.__hl_dot')!, '::before');
    expect(dot.display).toBe('inline-block');
    expect(dot.width).not.toBe('auto');
  });

  it('shows the dot of the first status and of the status after a hovered one', async () => {
    const menu = await openedMenu();
    const first = within(menu).getByRole('menuitem', { name: 'New' });
    const second = within(menu).getByRole('menuitem', { name: 'In progress' });
    const dotVisibility = (item:HTMLElement) => getComputedStyle(item.querySelector('.__hl_dot')!, '::before').visibility;

    expect(dotVisibility(first)).toBe('visible');

    await userEvent.hover(first);

    expect(dotVisibility(first)).toBe('visible');
    expect(dotVisibility(second)).toBe('visible');
  });

  it('shows a read-only status with a colored lock and an uncolored label', async () => {
    const menu = await openedMenu();

    const item = within(menu).getByRole('menuitem', { name: 'Locked' });
    expect(item).toHaveAttribute('title', 'Work package is locked');
    expect(item.querySelector('svg')).toHaveClass('__hl_foreground', '__hl_status_3');
    expect(item.querySelector('.__hl_dot')).toBeNull();
  });

  it('saves a persisted work package when a status is chosen', async () => {
    const menu = await openedMenu();

    await userEvent.click(within(menu).getByRole('menuitem', { name: 'New' }));

    expect(projectedResource.status).toEqual({ id: '1', name: 'New' });
    expect(save).toHaveBeenCalledTimes(1);
    await waitFor(() => expect(showSave).toHaveBeenCalledTimes(1));
  });

  it('only sets the status of a new work package', async () => {
    fixture.destroy();
    fixture = TestBed.createComponent(HostComponent);
    fixture.componentInstance.workPackage = { id: 'new' } as WorkPackageResource;
    await fixture.whenStable();
    const menu = await openedMenu();

    await userEvent.click(within(menu).getByRole('menuitem', { name: 'New' }));

    expect(projectedResource.status).toEqual({ id: '1', name: 'New' });
    expect(save).not.toHaveBeenCalled();
  });

  it('opens once when clicked twice while loading', async () => {
    await userEvent.click(button());
    await userEvent.click(button());
    resolveForm();
    await fixture.whenStable();
    await settle();

    await waitFor(() => expect(menus()).toHaveLength(1));
    expect(getForm).toHaveBeenCalledTimes(1);
  });

  it('opens nothing and shows no toast when the button is aria-disabled', async () => {
    fixture.componentInstance.notAllowed.set(true);
    await fixture.whenStable();

    fireEvent.click(button());
    await fixture.whenStable();
    await settle();

    expect(getForm).not.toHaveBeenCalled();
    expect(addError).not.toHaveBeenCalled();
    expect(menus()).toHaveLength(0);
  });

  it('shows the blocked toast and keeps focus on the button when the loaded form is not writable', async () => {
    writable = false;
    button().focus();
    await userEvent.keyboard('{Enter}');
    resolveForm();
    await fixture.whenStable();
    await settle();

    expect(addError).toHaveBeenCalledWith('Status is blocked');
    expect(menus()).toHaveLength(0);
    expect(button()).toHaveFocus();
    expect(button()).toHaveAttribute('aria-expanded', 'false');
  });
});

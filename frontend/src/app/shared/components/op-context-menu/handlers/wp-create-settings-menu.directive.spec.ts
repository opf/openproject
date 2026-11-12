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
import { settlePopover } from 'core-common/testing/timing';
import { FormResource } from 'core-app/features/hal/resources/form-resource';
import { States } from 'core-app/core/states/states.service';
import { HalResourceEditingService } from 'core-app/shared/components/fields/edit/services/hal-resource-editing.service';
import { OpActionMenuComponent } from 'core-app/shared/components/op-context-menu/action-menu/op-action-menu.component';
import {
  OpActionMenuTriggerDirective,
} from 'core-app/shared/components/op-context-menu/action-menu/op-action-menu-trigger.directive';
import { WorkPackageCreateSettingsMenuDirective } from './wp-create-settings-menu.directive';

@Component({
  imports: [OpActionMenuComponent, OpActionMenuTriggerDirective, WorkPackageCreateSettingsMenuDirective],
  template: `
    <op-action-menu wpCreateSettingsMenu align="end" label="Settings">
      <button opActionMenuTrigger type="button" aria-label="Settings"><i aria-hidden="true"></i></button>
    </op-action-menu>
  `,
})
class HostComponent {}

describe('WorkPackageCreateSettingsMenuDirective', () => {
  let fixture:ComponentFixture<HostComponent>;
  let form:Partial<FormResource>;

  const button = () => screen.getByRole('button', { name: 'Settings' });

  beforeEach(async () => {
    form = {};

    await TestBed.configureTestingModule({
      imports: [HostComponent],
      providers: [
        { provide: States, useValue: { workPackages: { get: () => ({ value: { id: 'new' } }) } } },
        {
          provide: HalResourceEditingService,
          useValue: { changeFor: () => ({ getForm: () => Promise.resolve(form) }) },
        },
      ],
    }).compileComponents();

    fixture = TestBed.createComponent(HostComponent);
    await fixture.whenStable();
  });

  afterEach(() => fixture.destroy());

  it('lists the form configuration links with their href', async () => {
    form = {
      customFields: { href: '/custom_fields', name: 'Custom fields' },
      configureForm: { href: '/configure', name: 'Configure form' },
    } as unknown as Partial<FormResource>;

    await userEvent.click(button());
    await fixture.whenStable();
    await settlePopover();

    const menu = await screen.findByRole('menu', { name: 'Settings' });
    const items = within(menu).getAllByRole('menuitem');
    expect(items.map((item) => item.textContent?.trim())).toEqual(['Custom fields', 'Configure form']);
    expect(items[0]).toHaveAttribute('href', '/custom_fields');
    expect(items[1]).toHaveAttribute('href', '/configure');
    items.forEach((item) => expect(item.querySelector('svg')).not.toBeNull());
    expect(menu.querySelector('.op-icon, [class^="icon-"], [class*=" icon-"]')).toBeNull();
  });

  it('opens nothing when the form offers neither link', async () => {
    button().focus();
    await userEvent.keyboard('{Enter}');
    await fixture.whenStable();
    await settlePopover();

    expect(screen.queryByRole('menu', { name: 'Settings' })).toBeNull();
    expect(button()).toHaveAttribute('aria-expanded', 'false');
    expect(button()).toHaveFocus();
  });
});

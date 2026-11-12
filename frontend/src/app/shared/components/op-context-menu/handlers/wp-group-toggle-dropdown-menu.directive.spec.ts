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
import { I18nService } from 'core-app/core/i18n/i18n.service';
import {
  WorkPackageViewCollapsedGroupsService,
} from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-collapsed-groups.service';
import { OpActionMenuComponent } from 'core-app/shared/components/op-context-menu/action-menu/op-action-menu.component';
import {
  OpActionMenuTriggerDirective,
} from 'core-app/shared/components/op-context-menu/action-menu/op-action-menu-trigger.directive';
import { OpTooltipDirective } from 'core-app/shared/components/primer/tooltip.directive';
import { WorkPackageGroupToggleDropdownMenuDirective } from './wp-group-toggle-dropdown-menu.directive';

@Component({
  imports: [OpActionMenuComponent, OpActionMenuTriggerDirective, OpTooltipDirective, WorkPackageGroupToggleDropdownMenuDirective],
  template: `
    <op-action-menu wpGroupToggleDropdown label="Collapse or expand groups">
      <button opActionMenuTrigger opTooltip label="Collapse or expand groups" type="button"><i aria-hidden="true"></i></button>
    </op-action-menu>
  `,
})
class HostComponent {}

describe('WorkPackageGroupToggleDropdownMenuDirective', () => {
  let fixture:ComponentFixture<HostComponent>;
  let groups:{
    allGroupsAreCollapsed:boolean;
    allGroupsAreExpanded:boolean;
    setAllGroupsCollapseStateTo:ReturnType<typeof vi.fn>;
  };

  const button = () => screen.getByRole('button', { name: 'Collapse or expand groups' });
  const openMenu = async () => {
    await userEvent.click(button());
    await fixture.whenStable();
    await settlePopover();
    return screen.findByRole('menu', { name: 'Collapse or expand groups' });
  };

  beforeEach(async () => {
    window.I18n.store({
      en: { js: { button_collapse_all: 'Collapse all', button_expand_all: 'Expand all' } },
    });
    groups = {
      allGroupsAreCollapsed: false,
      allGroupsAreExpanded: false,
      setAllGroupsCollapseStateTo: vi.fn(),
    };

    await TestBed.configureTestingModule({
      imports: [HostComponent],
      providers: [
        { provide: I18nService, useValue: { t: (key:string) => window.I18n.t(key) } },
        { provide: WorkPackageViewCollapsedGroupsService, useValue: groups },
      ],
    }).compileComponents();

    fixture = TestBed.createComponent(HostComponent);
    await fixture.whenStable();
  });

  afterEach(() => fixture.destroy());

  it('lists Collapse all and Expand all with Octicons', async () => {
    const menu = await openMenu();

    const items = within(menu).getAllByRole('menuitem');
    expect(items.map((item) => item.textContent?.trim())).toEqual(['Collapse all', 'Expand all']);
    items.forEach((item) => expect(item.querySelector('svg')).not.toBeNull());
    expect(menu.querySelector('.op-icon, [class^="icon-"], [class*=" icon-"]')).toBeNull();
  });

  it('disables Collapse all while all groups are collapsed', async () => {
    groups.allGroupsAreCollapsed = true;
    const menu = await openMenu();

    expect(within(menu).getByRole('menuitem', { name: 'Collapse all' })).toHaveAttribute('aria-disabled', 'true');
    expect(within(menu).getByRole('menuitem', { name: 'Expand all' })).not.toHaveAttribute('aria-disabled', 'true');
  });

  it('expands all groups and returns focus to the button', async () => {
    const menu = await openMenu();

    await userEvent.click(within(menu).getByRole('menuitem', { name: 'Expand all' }));
    await settlePopover();

    expect(groups.setAllGroupsCollapseStateTo).toHaveBeenCalledWith(false);
    expect(button()).toHaveFocus();
  });
});

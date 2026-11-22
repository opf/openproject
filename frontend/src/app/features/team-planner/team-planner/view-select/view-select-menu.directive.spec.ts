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
import { userEvent } from 'vitest/browser';
import { OpActionMenuComponent } from 'core-app/shared/components/op-context-menu/action-menu/op-action-menu.component';
import {
  OpActionMenuTriggerDirective,
} from 'core-app/shared/components/op-context-menu/action-menu/op-action-menu-trigger.directive';
import {
  TeamPlannerViewOptionKey,
  TeamPlannerViewOptions,
} from 'core-app/features/team-planner/team-planner/planner/team-planner.component';
import { TeamPlannerViewSelectMenuDirective } from './view-select-menu.directive';

@Component({
  imports: [OpActionMenuComponent, OpActionMenuTriggerDirective, TeamPlannerViewSelectMenuDirective],
  schemas: [CUSTOM_ELEMENTS_SCHEMA],
  template: `
    <op-action-menu opTeamPlannerViewSelectDropdown
                    label="Select view"
                    [viewOptions]="viewOptions"
                    [currentView]="currentView"
                    (viewSelected)="selected.push($event)">
      <button opActionMenuTrigger type="button">Work week</button>
    </op-action-menu>
  `,
})
class HostComponent {
  currentView:TeamPlannerViewOptionKey = 'resourceTimelineWeek';

  selected:TeamPlannerViewOptionKey[] = [];

  viewOptions = {
    resourceTimelineWorkWeek: { buttonText: 'Work week' },
    resourceTimelineWeek: { buttonText: '1-week' },
    resourceTimelineTwoWeeks: { buttonText: '2-week' },
  } as unknown as TeamPlannerViewOptions;
}

describe('TeamPlannerViewSelectMenuDirective', () => {
  let fixture:ComponentFixture<HostComponent>;

  const openMenu = async () => {
    await userEvent.click(screen.getByRole('button', { name: 'Work week' }));
    return screen.findByRole('menu', { name: 'Select view' });
  };

  beforeEach(async () => {
    await TestBed.configureTestingModule({ imports: [HostComponent] }).compileComponents();
    fixture = TestBed.createComponent(HostComponent);
    await fixture.whenStable();
  });

  afterEach(() => fixture.destroy());

  it('lists the views and marks the current one as selected', async () => {
    const menu = await openMenu();
    const items = within(menu).getAllByRole('menuitemradio');

    expect(items).toHaveLength(3);
    ['Work week', '1-week', '2-week'].forEach((name, index) => expect(items[index]).toHaveAccessibleName(name));
    expect(within(menu).getByRole('menuitemradio', { checked: true })).toHaveAccessibleName('1-week');
  });

  it('emits the chosen view', async () => {
    const menu = await openMenu();

    await userEvent.click(within(menu).getByRole('menuitemradio', { name: '2-week' }));

    expect(fixture.componentInstance.selected).toEqual(['resourceTimelineTwoWeeks']);
  });

  it('closes without emitting when the current view is chosen', async () => {
    const menu = await openMenu();

    await userEvent.click(within(menu).getByRole('menuitemradio', { name: '1-week' }));

    await waitFor(() => expect(screen.queryByRole('menu', { name: 'Select view' })).not.toBeInTheDocument());
    expect(fixture.componentInstance.selected).toEqual([]);
  });
});

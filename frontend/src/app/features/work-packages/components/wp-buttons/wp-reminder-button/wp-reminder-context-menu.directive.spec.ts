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
import '@openproject/primer-view-components/app/components/primer/alpha/tool_tip.js';
import { AsyncPipe } from '@angular/common';
import { EMPTY, of } from 'rxjs';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { ActionsService } from 'core-app/core/state/actions/actions.service';
import { IanBellService } from 'core-app/features/in-app-notifications/bell/state/ian-bell.service';
import { OpTooltipDirective } from 'core-app/shared/components/primer/tooltip.directive';
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { screen, within } from '@testing-library/dom';
import { userEvent } from 'vitest/browser';
import { settlePopover } from 'core-common/testing/timing';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { OpModalService } from 'core-app/shared/components/modal/modal.service';
import { OpActionMenuComponent } from 'core-app/shared/components/op-context-menu/action-menu/op-action-menu.component';
import {
  OpActionMenuTriggerDirective,
} from 'core-app/shared/components/op-context-menu/action-menu/op-action-menu-trigger.directive';
import { WorkPackageReminderModalComponent } from 'core-app/features/work-packages/components/wp-reminder-modal/wp-reminder.modal';
import { ReminderPreset } from 'core-app/features/work-packages/components/wp-reminder-modal/reminder.types';
import { WorkPackageReminderContextMenuDirective } from './wp-reminder-context-menu.directive';
import { WorkPackageReminderButtonComponent } from './wp-reminder-button.component';

describe('WorkPackageReminderContextMenuDirective', () => {
  let fixture:ComponentFixture<WorkPackageReminderButtonComponent>;
  let show:ReturnType<typeof vi.fn>;

  const openMenu = async () => {
    await userEvent.click(screen.getByRole('button', { name: 'Set reminder' }));
    await fixture.whenStable();
    await settlePopover();
    return screen.findByRole('menu', { name: 'Set a reminder' });
  };

  beforeEach(async () => {
    window.I18n.store({
      en: {
        js: {
          work_packages: {
            reminders: {
              title: { new: 'Set a reminder' },
              button_label: 'Set reminder',
              presets: {
                tomorrow: 'Tomorrow',
                three_days: 'In 3 days',
                week: 'In a week',
                month: 'In a month',
                custom: 'At a particular date/time',
              },
            },
          },
        },
      },
    });
    show = vi.fn();

    await TestBed.configureTestingModule({
      declarations: [WorkPackageReminderButtonComponent],
      imports: [AsyncPipe, OpActionMenuComponent, OpActionMenuTriggerDirective, WorkPackageReminderContextMenuDirective, OpTooltipDirective],
      providers: [
        { provide: I18nService, useValue: { t: (key:string) => window.I18n.t(key) } },
        { provide: OpModalService, useValue: { show } },
        { provide: IanBellService, useValue: {} },
        { provide: ActionsService, useValue: { ofType: () => EMPTY } },
        { provide: ApiV3Service, useValue: { work_packages: { id: () => ({ reminders: { get: () => of({ total: 0 }) } }) } } },
      ],
    }).compileComponents();

    fixture = TestBed.createComponent(WorkPackageReminderButtonComponent);
    fixture.componentRef.setInput('workPackage', { id: '42' });
    await fixture.whenStable();
  });

  afterEach(() => fixture.destroy());

  it('lists the presets', async () => {
    const menu = await openMenu();

    const group = within(menu).getByRole('group', { name: 'Set a reminder' });
    expect(within(menu).getByText('Set a reminder')).toBeVisible();
    expect(within(group).getAllByRole('menuitem').map((item) => item.textContent?.trim())).toEqual([
      'Tomorrow',
      'In 3 days',
      'In a week',
      'In a month',
      'At a particular date/time',
    ]);
  });

  it('opens the reminder modal with the chosen preset', async () => {
    const menu = await openMenu();

    await userEvent.click(within(menu).getByRole('menuitem', { name: 'In a week' }));

    expect(show).toHaveBeenCalledTimes(1);
    expect(show).toHaveBeenCalledWith(
      WorkPackageReminderModalComponent,
      'global',
      { workPackage: fixture.componentInstance.workPackage, preset: ReminderPreset.WEEK },
      false,
      true,
    );
  });
});

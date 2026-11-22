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
import { Component, NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { provideHttpClient } from '@angular/common/http';
import { screen, waitFor, within } from '@testing-library/dom';
import { type Mock } from 'vitest';
import { userEvent } from 'vitest/browser';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { OpModalService } from 'core-app/shared/components/modal/modal.service';
import { OpActionMenuComponent } from 'core-app/shared/components/op-context-menu/action-menu/op-action-menu.component';
import {
  OpActionMenuTriggerDirective,
} from 'core-app/shared/components/op-context-menu/action-menu/op-action-menu-trigger.directive';
import { Board } from 'core-app/features/boards/board/board';
import { BoardConfigurationModalComponent } from 'core-app/features/boards/board/configuration-modal/board-configuration.modal';
import { EditableToolbarTitleComponent } from 'core-app/shared/components/editable-toolbar-title/editable-toolbar-title.component';
import { AutofocusDirective } from 'core-app/shared/directives/focus/autofocus.directive';
import { FocusHelperService } from 'core-app/shared/directives/focus/focus-helper';
import { OpSharedModule } from 'core-app/shared/shared.module';
import { BoardsToolbarMenuDirective } from './boards-toolbar-menu.directive';

@Component({
  standalone: false,
  template: `
    <editable-toolbar-title title="Board" />
    <op-action-menu boardsToolbarMenu [boardsToolbarMenu-resource]="board" label="More">
      <button opActionMenuTrigger type="button">More actions</button>
    </op-action-menu>
  `,
})
class HostComponent {
  readonly board = { id: '1', projectId: 'p', grid: { updateImmediately: true, delete: true } } as unknown as Board;
}

@NgModule({
  imports: [OpSharedModule, BoardsToolbarMenuDirective],
  declarations: [HostComponent],
})
class HostModule {}

describe('BoardsToolbarMenuDirective', () => {
  let fixture:ComponentFixture<HostComponent>;
  let show:Mock<(...args:Parameters<OpModalService['show']>) => void>;

  const openMenu = async () => {
    await userEvent.click(screen.getByRole('button', { name: 'More actions' }));
    return screen.findByRole('menu', { name: 'More' });
  };

  beforeEach(async () => {
    window.I18n.store({
      en: {
        js: {
          toolbar: { settings: { configure_view: 'Configure view', page_settings: 'Rename view', delete: 'Delete' } },
          text_query_destroy_confirmation: 'Are you sure?',
          work_packages: { query: { click_to_edit_query_name: 'Board title' } },
        },
      },
    });
    show = vi.fn();

    TestBed.overrideModule(HostModule, {
      set: {
        imports: [CommonModule, FormsModule, OpActionMenuComponent, OpActionMenuTriggerDirective, BoardsToolbarMenuDirective],
        declarations: [HostComponent, EditableToolbarTitleComponent, AutofocusDirective],
      },
    });
    await TestBed.configureTestingModule({
      imports: [HostModule],
      providers: [
        provideHttpClient(),
        { provide: I18nService, useValue: { t: (key:string) => window.I18n.t(key) } },
        { provide: OpModalService, useValue: { show } },
        { provide: FocusHelperService, useValue: { focus: () => undefined } satisfies Partial<FocusHelperService> },
      ],
    }).compileComponents();

    fixture = TestBed.createComponent(HostComponent);
    await fixture.whenStable();
  });

  afterEach(() => fixture.destroy());

  it('lists the actions with Delete last after a separator', async () => {
    const menu = await openMenu();
    const items = within(menu).getAllByRole('menuitem');

    expect([...menu.children].map((entry) => entry.getAttribute('role'))).toEqual(['none', 'none', 'separator', 'none']);
    expect(items).toHaveLength(3);
    expect(items[0]).toHaveAccessibleName('Configure view');
    expect(items[1]).toHaveAccessibleName('Rename view');
    expect(items[2]).toHaveAccessibleName('Delete');
    expect(items[2].closest('li')).toHaveClass('ActionListItem--danger');
  });

  it('renders an Octicon for each action', async () => {
    const menu = await openMenu();

    const icons = within(menu).getAllByRole('menuitem').map((item) => item.querySelector('svg'));

    expect(icons[0]).toHaveClass('octicon-gear');
    expect(icons[1]).toHaveClass('octicon-pencil');
    expect(icons[2]).toHaveClass('octicon-trash');
  });

  it('opens the configuration modal', async () => {
    const menu = await openMenu();

    await userEvent.click(within(menu).getByRole('menuitem', { name: 'Configure view' }));

    expect(show).toHaveBeenCalledExactlyOnceWith(
      BoardConfigurationModalComponent,
      expect.anything(),
      { board: fixture.componentInstance.board },
    );
  });

  it('moves focus to the title input when renaming', async () => {
    const menu = await openMenu();

    await userEvent.click(within(menu).getByRole('menuitem', { name: 'Rename view' }));

    await waitFor(() => expect(screen.getByRole('textbox', { name: /Board title/ })).toHaveFocus());
    await waitFor(() => expect(screen.queryByRole('menu', { name: 'More' })).not.toBeInTheDocument());
    expect(screen.getByRole('textbox', { name: /Board title/ })).toHaveFocus();
  });
});

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

import { AsyncPipe, NgClass } from '@angular/common';
import { provideHttpClient } from '@angular/common/http';
import { TestBed } from '@angular/core/testing';
import { fireEvent, screen } from '@testing-library/dom';
import { States } from 'core-app/core/states/states.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { GridResource } from 'core-app/features/hal/resources/grid-resource';
import { HalResourceService } from 'core-app/features/hal/services/hal-resource.service';
import { OpIconComponent } from 'core-app/shared/components/icon/icon.component';
import { OpModalService } from 'core-app/shared/components/modal/modal.service';
import { OPContextMenuService } from 'core-app/shared/components/op-context-menu/op-context-menu.service';
import { OpTooltipDirective } from 'core-app/shared/components/primer/tooltip.directive';
import { ToastService } from 'core-app/shared/components/toaster/toast.service';
import { of, Subject } from 'rxjs';
import { Board } from '../board';
import { BoardConfigurationModalComponent } from '../configuration-modal/board-configuration.modal';
import { BoardsMenuButtonComponent } from './boards-menu-button.component';
import { BoardsToolbarMenuDirective } from './boards-toolbar-menu.directive';

describe('BoardsMenuButtonComponent', () => {
  const showMenu = vi.fn<OPContextMenuService['show']>();
  const showModal = vi.fn<OpModalService['show']>();

  beforeEach(async () => {
    showMenu.mockClear();
    showModal.mockClear();

    await TestBed
      .configureTestingModule({
        imports: [AsyncPipe, NgClass, OpTooltipDirective],
        declarations: [OpIconComponent, BoardsMenuButtonComponent, BoardsToolbarMenuDirective],
        providers: [
          provideHttpClient(),
          States,
          { provide: I18nService, useValue: { t: (key:string) => key } },
          { provide: OPContextMenuService, useValue: { show: showMenu, close: () => undefined, isActive: () => false } },
          { provide: OpModalService, useValue: { show: showModal } },
          { provide: ToastService, useValue: {} },
        ],
      })
      .compileComponents();
  });

  it('labels the icon-only button with its tooltip', async () => {
    const fixture = TestBed.createComponent(BoardsMenuButtonComponent);
    fixture.componentRef.setInput('board$', of({} as Board));
    await fixture.whenStable();

    const button = screen.getByRole('button');

    expect(button).toHaveAccessibleName('js.button_more');
    expect(button.nextElementSibling).toHaveAttribute('for', button.id);
  });

  it('opens settings for the latest board emitted by the toolbar stream', async () => {
    const boards = new Subject<Board>();
    const hal = TestBed.inject(HalResourceService);
    const boardFor = (id:number) => new Board(hal.createHalResourceOfClass(GridResource, {
      options: {},
      widgets: [],
      _links: { self: { href: `/api/v3/grids/${id}` } },
    }));

    const fixture = TestBed.createComponent(BoardsMenuButtonComponent);
    fixture.componentRef.setInput('board$', boards);
    await fixture.whenStable();

    boards.next(boardFor(1));
    await fixture.whenStable();
    const latest = boardFor(2);
    boards.next(latest);
    await fixture.whenStable();

    fireEvent.click(screen.getByRole('button', { name: 'js.button_more' }));
    const [handler] = showMenu.mock.calls[0];
    const configure = handler.locals.items.find((item) => item.linkText === 'js.toolbar.settings.configure_view');
    expect(configure).toBeDefined();
    configure?.onClick?.(new MouseEvent('click'));

    expect(showModal).toHaveBeenCalledWith(BoardConfigurationModalComponent, expect.anything(), { board: latest });

    fixture.destroy();
    expect(boards.observed).toBe(false);
  });
});

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

import { provideHttpClient } from '@angular/common/http';
import { ApplicationRef } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { FormsModule } from '@angular/forms';
import { fireEvent, screen } from '@testing-library/dom';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { GridResource } from 'core-app/features/hal/resources/grid-resource';
import { HalResourceService } from 'core-app/features/hal/services/hal-resource.service';
import { OpModalLocalsToken, OpModalService } from 'core-app/shared/components/modal/modal.service';
import { Subject } from 'rxjs';
import { page } from 'vitest/browser';
import { Board } from '../board';
import { BoardService } from '../board.service';
import { BoardConfigurationModalComponent } from './board-configuration.modal';
import { BoardConfigurationService } from './board-configuration.service';
import { BoardHighlightingTabComponent } from './tabs/highlighting-tab.component';

describe('BoardConfigurationModalComponent', () => {
  const entireCardLabel = 'js.card.highlighting.entire_card_by';
  let board:Board;
  let save:ReturnType<typeof vi.fn<BoardService['save']>>;
  let saveResponse:Subject<Board>;
  let close:ReturnType<typeof vi.fn<OpModalService['close']>>;

  beforeEach(async () => {
    saveResponse = new Subject<Board>();
    save = vi.fn<BoardService['save']>().mockReturnValue(saveResponse);
    close = vi.fn<OpModalService['close']>();

    await TestBed.configureTestingModule({
      declarations: [BoardConfigurationModalComponent, BoardHighlightingTabComponent],
      imports: [FormsModule],
      providers: [
        provideHttpClient(),
        BoardConfigurationService,
        { provide: I18nService, useValue: { t: (key:string) => key } },
        { provide: BoardService, useValue: { save } },
        { provide: OpModalLocalsToken, useFactory: () => ({ board, service: { close } }) },
      ],
    }).compileComponents();

    const grid = TestBed.inject(HalResourceService).createHalResourceOfClass(GridResource, {
      options: { highlightingMode: 'priority' },
      widgets: [],
      _links: { self: { href: '/api/v3/grids/1' } },
    });
    board = new Board(grid);
  });

  it('renders the highlighting portal and persists the selected mode on Apply', async () => {
    const fixture = TestBed.createComponent(BoardConfigurationModalComponent);
    await fixture.whenStable();

    const entireCard = await screen.findByRole('radio', { name: entireCardLabel });
    const attribute = screen.getByRole('combobox');
    const none = screen.getByRole('radio', { name: 'js.work_packages.table_configuration.highlighting_mode.none' });
    expect(entireCard).toBeChecked();
    expect(attribute).toHaveValue('priority');

    fireEvent.click(none);
    await fixture.whenStable();
    expect(none).toBeChecked();
    expect(attribute).toBeDisabled();

    fireEvent.click(entireCard);
    await fixture.whenStable();
    expect(entireCard).toBeChecked();
    expect(none).not.toBeChecked();
    expect(attribute).toBeEnabled();
    expect(attribute).toHaveValue('priority');

    fireEvent.change(attribute, { target: { value: 'type' } });
    expect(board.highlightingMode).toBe('priority');

    fireEvent.click(screen.getByRole('button', { name: 'js.modals.button_apply' }));
    expect(board.highlightingMode).toBe('type');
    expect(save).toHaveBeenCalledWith(board);
    expect(close).not.toHaveBeenCalled();

    saveResponse.next(board);
    expect(close).toHaveBeenCalledOnce();

    fixture.destroy();
    expect(entireCard).not.toBeInTheDocument();
  });

  it('cancels without persisting changes', async () => {
    await page.viewport(1280, 800);
    const fixture = TestBed.createComponent(BoardConfigurationModalComponent);
    await fixture.whenStable();
    await screen.findByRole('radio', { name: entireCardLabel });

    fireEvent.change(screen.getByRole('combobox'), { target: { value: 'type' } });
    fireEvent.click(screen.getByRole('button', { name: 'js.modals.button_cancel' }));

    expect(close).toHaveBeenCalledOnce();
    expect(save).not.toHaveBeenCalled();
    expect(board.highlightingMode).toBe('priority');
  });

  it('does not attach a portal if the modal is destroyed before the initial tab opens', () => {
    vi.useFakeTimers({ toFake: ['setTimeout', 'clearTimeout'] });
    try {
      const app = TestBed.inject(ApplicationRef);
      const viewCount = app.viewCount;
      const fixture = TestBed.createComponent(BoardConfigurationModalComponent);
      fixture.detectChanges();
      fixture.destroy();

      vi.runOnlyPendingTimers();

      expect(app.viewCount).toBe(viewCount);
    } finally {
      vi.useRealTimers();
    }
  });
});

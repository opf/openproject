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

import { ChangeDetectionStrategy, Component, signal } from '@angular/core';
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { fireEvent, screen } from '@testing-library/dom';
import { userEvent } from 'vitest/browser';
import { OPContextMenuService } from 'core-app/shared/components/op-context-menu/op-context-menu.service';
import { OpContextMenuTrigger } from './op-context-menu-trigger.directive';

@Component({
  template: `
    <button type="button" class="button" opContextMenuTrigger [attr.aria-disabled]="disabled() || null">
      Open menu
    </button>
  `,
  changeDetection: ChangeDetectionStrategy.OnPush,
  standalone: false,
})
class HostComponent {
  readonly disabled = signal(true);
}

describe('OpContextMenuTrigger', () => {
  let fixture:ComponentFixture<HostComponent>;
  let contextMenu:{ show:ReturnType<typeof vi.fn>, close:ReturnType<typeof vi.fn>, isActive:() => boolean };

  const openWithKeyboard = (button:HTMLElement) => {
    fireEvent.keyDown(button, {
      key: 'F10', code: 'F10', keyCode: 121, which: 121, shiftKey: true, altKey: true,
    });
  };

  beforeEach(async () => {
    contextMenu = { show: vi.fn(), close: vi.fn(), isActive: () => false };

    await TestBed
      .configureTestingModule({
        declarations: [HostComponent, OpContextMenuTrigger],
        providers: [{ provide: OPContextMenuService, useValue: contextMenu }],
      })
      .compileComponents();

    fixture = TestBed.createComponent(HostComponent);
    await fixture.whenStable();
  });

  afterEach(() => {
    fixture.destroy();
  });

  it('ignores click and Shift+Alt+F10 while aria-disabled', () => {
    const button = screen.getByRole('button', { name: 'Open menu' });

    fireEvent.click(button);
    openWithKeyboard(button);

    expect(contextMenu.show).not.toHaveBeenCalled();
  });

  it('opens on click and Shift+Alt+F10 once enabled', async () => {
    fixture.componentInstance.disabled.set(false);
    await fixture.whenStable();

    const button = screen.getByRole('button', { name: 'Open menu' });

    fireEvent.click(button);
    expect(contextMenu.show).toHaveBeenCalledTimes(1);

    openWithKeyboard(button);
    expect(contextMenu.show).toHaveBeenCalledTimes(2);
  });

  it('keeps the resting background on hover while aria-disabled', async () => {
    const button = screen.getByRole('button', { name: 'Open menu' });
    button.style.transition = 'none';
    const resting = getComputedStyle(button).backgroundColor;

    await userEvent.hover(button);

    expect(button).toHaveStyle({ backgroundColor: resting });
  });
});

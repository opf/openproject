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
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { screen, within } from '@testing-library/dom';
import { type Mock } from 'vitest';
import { userEvent } from 'vitest/browser';
import { firstValueFrom, Subject } from 'rxjs';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import 'core-app/shared/shared.module';
import { IconTriggeredContextMenuComponent } from './icon-triggered-context-menu.component';
import { OpContextMenuItem } from 'core-app/shared/components/op-context-menu/op-context-menu.types';

describe('IconTriggeredContextMenuComponent', () => {
  let fixture:ComponentFixture<IconTriggeredContextMenuComponent>;
  let onClick:() => boolean;
  let onClickSpy:Mock<() => void>;

  const mount = async (factory:() => Promise<OpContextMenuItem[]>, showTooltip?:boolean) => {
    fixture = TestBed.createComponent(IconTriggeredContextMenuComponent);
    fixture.componentRef.setInput('customAriaLabel', 'Widget menu');
    fixture.componentRef.setInput('menuItemsFactory', factory);
    if (showTooltip !== undefined) {
      fixture.componentRef.setInput('showTooltip', showTooltip);
    }
    await fixture.whenStable();
  };

  const trigger = () => screen.getByRole('button', { name: 'Widget menu' });

  const openMenu = async () => {
    await userEvent.click(trigger());
    return screen.findByRole('menu', { name: 'Widget menu' });
  };

  const tooltip = () => screen.queryByRole('tooltip', { hidden: true });

  beforeEach(async () => {
    onClickSpy = vi.fn<() => void>();
    onClick = () => { onClickSpy(); return true; };

    await TestBed.configureTestingModule({
      providers: [
        { provide: I18nService, useValue: { t: (key:string) => key } },
      ],
    }).compileComponents();
  });

  afterEach(() => fixture.destroy());

  describe('with loaded items', () => {
    beforeEach(() => mount(() => Promise.resolve([
      { linkText: 'Configure view', onClick },
      { linkText: 'Remove widget', onClick },
    ])));

    it('opens a menu named after the button with the loaded items', async () => {
      const menu = await openMenu();

      expect(menu).toBeVisible();
      expect(within(menu).getAllByRole('menuitem').map((item) => item.textContent?.trim())).toEqual([
        'Configure view',
        'Remove widget',
      ]);
    });

    it('calls the chosen item', async () => {
      const menu = await openMenu();

      await userEvent.click(within(menu).getByRole('menuitem', { name: 'Remove widget' }));

      expect(onClickSpy).toHaveBeenCalledTimes(1);
    });
  });

  describe('with items that arrive later', () => {
    let items:Subject<OpContextMenuItem[]>;

    beforeEach(async () => {
      items = new Subject<OpContextMenuItem[]>();
      await mount(() => firstValueFrom(items));
    });

    afterEach(() => vi.useRealTimers());

    it('opens once the items arrive', async () => {
      await userEvent.click(trigger());
      items.next([{ linkText: 'Configure view', onClick }]);

      expect(await screen.findByRole('menu', { name: 'Widget menu' })).toBeVisible();
    });

    it('stays closed past its deferred opening when Tab is pressed before the items arrive', async () => {
      await userEvent.click(trigger());
      await userEvent.keyboard('{Tab}');
      vi.useFakeTimers({ toFake: ['requestAnimationFrame', 'setTimeout'] });
      items.next([{ linkText: 'Configure view', onClick }]);
      await vi.runAllTimersAsync();

      expect(screen.queryByRole('menu', { name: 'Widget menu' })).not.toBeInTheDocument();
    });
  });

  it('shows its name as a tooltip to the south-east of the button', async () => {
    await mount(() => Promise.resolve([]));

    expect(trigger()).toBeInTheDocument();
    expect(tooltip()).toHaveTextContent('Widget menu');
    expect(tooltip()).toHaveAttribute('data-direction', 'se');
  });

  it('keeps its name without a tooltip when showTooltip is false', async () => {
    await mount(() => Promise.resolve([]), false);

    expect(trigger()).toHaveAttribute('aria-label', 'Widget menu');
    expect(tooltip()).not.toBeInTheDocument();
  });

  it('drops legacy icon classes without an Octicon', async () => {
    await mount(() => Promise.resolve([{ linkText: 'X', icon: 'icon-unmapped', onClick }]));

    const menu = await openMenu();
    const item = within(menu).getByRole('menuitem', { name: 'X' });

    expect(item).toHaveAccessibleName('X');
    expect(item.innerHTML).not.toMatch(/\bicon-unmapped\b/);
  });

  it('swaps legacy icon classes for Octicons in submenus too', async () => {
    await mount(() => Promise.resolve([{
      linkText: 'More',
      children: [
        { linkText: 'Delete', icon: 'icon-delete', onClick },
        { linkText: 'Unmapped', icon: 'icon-unmapped', onClick },
      ],
    }]));

    await openMenu();
    const submenu = screen.getByRole('menu', { name: 'More', hidden: true });
    const deleteItem = within(submenu).getByRole('menuitem', { name: 'Delete', hidden: true });
    const unmapped = within(submenu).getByRole('menuitem', { name: 'Unmapped', hidden: true });

    expect(deleteItem.querySelector('svg')).toHaveClass('octicon-trash');
    expect(deleteItem.innerHTML).not.toMatch(/\bicon-delete\b/);
    expect(unmapped.innerHTML).not.toMatch(/\bicon-unmapped\b/);
  });
});

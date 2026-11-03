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

import { ComponentFixture, TestBed } from '@angular/core/testing';
import { fireEvent, within } from '@testing-library/dom';
import { userEvent } from 'vitest/browser';
import { nextFrame, nextTask } from 'core-common/testing/timing';
import { OpContextMenuItem } from 'core-app/shared/components/op-context-menu/op-context-menu.types';
import { OpActionMenuComponent } from './op-action-menu.component';

describe('OpActionMenuComponent', () => {
  let fixture:ComponentFixture<OpActionMenuComponent>;
  let clicked:string[];

  const items = ():OpContextMenuItem[] => [
    { linkText: 'Open', icon: 'icon-view-split', onClick: () => { clicked.push('open'); return true; } },
    { linkText: 'Copy', disabled: true, onClick: () => { clicked.push('copy'); return true; } },
    { linkText: 'Link', href: '/x', onClick: () => false },
    { divider: true },
    {
      linkText: 'Move',
      octicon: 'op-arrow-in',
      children: [
        { linkText: 'Move to top', octicon: 'move-to-top', disabled: true, onClick: () => { clicked.push('top'); return true; } },
        { linkText: 'Move down', octicon: 'chevron-down', onClick: () => { clicked.push('down'); return true; } },
      ],
    },
  ];

  const settle = async () => { await nextTask(); await nextFrame(); await nextFrame(); };
  const menu = () => within(fixture.nativeElement as HTMLElement).getByRole('menu', { name: 'Row actions', hidden: true });
  const subMenu = () => within(fixture.nativeElement as HTMLElement).getByRole('menu', { name: 'Move', hidden: true });
  const popover = () => fixture.componentInstance.menuElement.popoverElement!;
  const open = async () => { popover().showPopover(); await settle(); };

  beforeEach(async () => {
    await TestBed.configureTestingModule({ imports: [OpActionMenuComponent] }).compileComponents();
    clicked = [];
    fixture = TestBed.createComponent(OpActionMenuComponent);
    fixture.componentRef.setInput('items', items());
    fixture.componentRef.setInput('label', 'Row actions');
    fixture.detectChanges();
    document.body.append(fixture.nativeElement as HTMLElement);
  });

  afterEach(() => {
    (fixture.nativeElement as HTMLElement).remove();
  });

  it('renders the items as a Primer ActionMenu', () => {
    const list = menu();

    const ownItems = within(list).getAllByRole('menuitem', { hidden: true }).filter((item) => item.closest('[role="menu"]') === list);

    expect(ownItems.map((item) => item.textContent?.trim())).toEqual(['Open', 'Copy', 'Link', 'Move']);
    expect(within(list).getByRole('menuitem', { name: 'Copy', hidden: true })).toHaveAttribute('aria-disabled', 'true');
    expect(within(list).getByRole('menuitem', { name: 'Link', hidden: true })).toHaveAttribute('href', '/x');
    expect(within(list).getByRole('separator', { hidden: true })).toBeInTheDocument();
    expect(within(list).getByRole('menuitem', { name: 'Move', hidden: true })).toHaveAttribute('aria-haspopup', 'true');
    expect(within(subMenu()).getAllByRole('menuitem', { hidden: true })).toHaveLength(2);
  });

  it('runs onClick and reports the activation', async () => {
    await open();
    const activated:string[] = [];
    fixture.componentInstance.activated.subscribe((item) => activated.push(item.linkText!));

    fireEvent.click(within(menu()).getByRole('menuitem', { name: 'Open' }));

    expect(clicked).toEqual(['open']);
    expect(activated).toEqual(['Open']);
  });

  it('ignores disabled items', async () => {
    await open();

    fireEvent.click(within(menu()).getByRole('menuitem', { name: 'Copy' }));

    expect(clicked).toEqual([]);
  });

  it('opens the submenu with ArrowRight and steps back with ArrowLeft', async () => {
    await open();
    within(menu()).getByRole('menuitem', { name: 'Move' }).focus();

    await userEvent.keyboard('{ArrowRight}');
    await settle();

    expect(within(subMenu()).getByRole('menuitem', { name: 'Move to top' })).toHaveFocus();

    await userEvent.keyboard('{ArrowLeft}');
    await settle();

    expect(popover()).toHaveAttribute('popover');
    expect(popover().matches(':popover-open')).toBe(true);
    expect(within(menu()).getByRole('menuitem', { name: 'Move' })).toHaveFocus();
  });

  it('closes only the submenu on Escape', async () => {
    await open();
    within(menu()).getByRole('menuitem', { name: 'Move' }).focus();
    await userEvent.keyboard('{ArrowRight}');
    await settle();

    await userEvent.keyboard('{Escape}');
    await settle();

    expect(popover().matches(':popover-open')).toBe(true);
    expect(within(menu()).getByRole('menuitem', { name: 'Move' })).toHaveFocus();
  });

  it('activates a submenu item and closes the whole menu', async () => {
    await open();
    within(menu()).getByRole('menuitem', { name: 'Move' }).focus();
    await userEvent.keyboard('{ArrowRight}');
    await settle();

    fireEvent.click(within(subMenu()).getByRole('menuitem', { name: 'Move down' }));
    await settle();

    expect(clicked).toEqual(['down']);
    expect(popover().matches(':popover-open')).toBe(false);
  });
});

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
import { ChangeDetectionStrategy, Component } from '@angular/core';
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { fireEvent, screen, waitFor, within } from '@testing-library/dom';
import { userEvent } from 'vitest/browser';
import { settlePopover } from 'core-common/testing/timing';
import { OpContextMenuCloseReason, OpContextMenuItem } from 'core-app/shared/components/op-context-menu/op-context-menu.types';
import { OpActionMenuComponent } from './op-action-menu.component';
import type { ActionMenuElement } from '@openproject/primer-view-components/app/components/primer/alpha/action_menu/action_menu_element';
import { OpActionMenuTriggerDirective } from './op-action-menu-trigger.directive';

describe('OpActionMenuComponent', () => {
  let fixture:ComponentFixture<OpActionMenuComponent>;
  let clicked:string[];

  const items = ():OpContextMenuItem[] => [
    { linkText: 'Open', icon: 'icon-view-split', onClick: () => { clicked.push('open'); return true; } },
    { linkText: 'Copy', disabled: true, onClick: () => { clicked.push('copy'); return true; } },
    { linkText: 'Link', href: '/x', class: 'detailsViewMenuItem', onClick: () => false },
    { linkText: 'Plain', onClick: () => true },
    { divider: true },
    {
      linkText: 'Move',
      octicon: 'op-arrow-in',
      children: [
        { linkText: 'Move to top', octicon: 'move-to-top', disabled: true, onClick: () => { clicked.push('top'); return true; } },
        { linkText: 'Move down', octicon: 'chevron-down', onClick: () => { clicked.push('down'); return true; } },
        { linkText: 'Hidden child', hidden: true, onClick: () => true },
      ],
    },
    { linkText: 'Display hierarchy', checked: true, onClick: () => true },
    { linkText: 'Hidden root', hidden: true, onClick: () => true },
  ];

  const settle = settlePopover;
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
    await fixture.whenStable();
  });

  it('renders the items as a Primer ActionMenu', () => {
    const list = menu();

    const ownItems = within(list).getAllByRole('menuitem', { hidden: true }).filter((item) => item.closest('[role="menu"]') === list);

    expect(ownItems.map((item) => item.textContent?.trim())).toEqual(['Open', 'Copy', 'Link', 'Plain', 'Move']);
    expect(within(list).getByRole('menuitem', { name: 'Copy', hidden: true })).toHaveAttribute('aria-disabled', 'true');
    expect(within(list).getByRole('menuitem', { name: 'Link', hidden: true })).toHaveAttribute('href', '/x');
    expect(within(list).getByRole('separator', { hidden: true })).toBeInTheDocument();
    expect(within(list).getByRole('menuitem', { name: 'Move', hidden: true })).toHaveAttribute('aria-haspopup', 'menu');
    expect(within(subMenu()).getAllByRole('menuitem', { hidden: true })).toHaveLength(2);
  });

  it('aligns labels beside legacy icons and Octicons', async () => {
    await open();

    const labelLeft = (name:string) => within(menu()).getByRole('menuitem', { name })
      .querySelector('.ActionListItem-label')!.getBoundingClientRect().left;

    expect(labelLeft('Open')).toBe(labelLeft('Move'));
  });

  it('runs onClick and reports the activation', async () => {
    await open();
    const activated:string[] = [];
    fixture.componentInstance.activated.subscribe((item) => activated.push(item.linkText ?? ''));

    fireEvent.click(within(menu()).getByRole('menuitem', { name: 'Open' }));

    expect(clicked).toEqual(['open']);
    expect(activated).toEqual(['Open']);
  });

  it('ignores disabled items', async () => {
    await open();

    fireEvent.click(within(menu()).getByRole('menuitem', { name: 'Copy' }));

    expect(clicked).toEqual([]);
  });

  it('leaves hidden items out at every depth', async () => {
    await open();
    expect(within(menu()).queryByRole('menuitem', { name: 'Hidden root' })).toBeNull();

    within(menu()).getByRole('menuitem', { name: 'Move' }).focus();
    await userEvent.keyboard('{ArrowRight}');
    await settle();

    expect(within(subMenu()).queryByRole('menuitem', { name: 'Hidden child' })).toBeNull();
    expect(within(subMenu()).getByRole('menuitem', { name: 'Move down' })).toBeInTheDocument();
  });

  it('renders a checked item as a menuitemcheckbox', async () => {
    await open();

    expect(within(menu()).getByRole('menuitemcheckbox', { name: 'Display hierarchy' })).toHaveAttribute('aria-checked', 'true');
  });

  it.each(['button', 'link'])('marks checked %s items with Primer\'s check mark and hides it on unchecked ones', async (kind) => {
    fixture.componentRef.setInput('items', [true, false].map((checked) => ({
      linkText: checked ? 'Checked' : 'Unchecked',
      checked,
      href: kind === 'link' ? '/x' : undefined,
      onClick: () => true,
    })));
    await fixture.whenStable();
    await open();

    const checked = within(menu()).getByRole('menuitemcheckbox', { name: 'Checked' });
    const unchecked = within(menu()).getByRole('menuitemcheckbox', { name: 'Unchecked' });
    const checkmark = (item:HTMLElement) => item.querySelector<SVGElement>('.ActionListItem-singleSelectCheckmark')!;

    expect(checkmark(checked)).toHaveClass('octicon-check');
    expect(getComputedStyle(checkmark(checked)).visibility).toBe('visible');
    expect(getComputedStyle(checkmark(unchecked)).visibility).toBe('hidden');
    expect(checked.querySelector('.FormControl-checkbox')).toBeNull();
    expect(checked).toHaveAttribute('aria-checked', 'true');
    expect(unchecked).toHaveAttribute('aria-checked', 'false');
  });

  it('leaves out a submenu whose items are all hidden, with its divider', async () => {
    fixture.componentRef.setInput('items', [
      { linkText: 'First', onClick: () => true },
      { divider: true },
      {
        linkText: 'Move',
        children: [{ linkText: 'Hidden', hidden: true, onClick: () => true }],
      },
    ]);
    await fixture.whenStable();

    expect(within(menu()).queryByRole('menuitem', { name: 'Move', hidden: true })).toBeNull();
    expect([...menu().children].map((child) => child.getAttribute('role'))).toEqual(['none']);
  });

  it('collapses dividers at the edges and around hidden items', async () => {
    fixture.componentRef.setInput('items', [
      { divider: true },
      { linkText: 'First', onClick: () => true },
      { divider: true },
      { linkText: 'Hidden', hidden: true, onClick: () => true },
      { divider: true },
      { linkText: 'Second', onClick: () => true },
      { divider: true },
    ]);
    await fixture.whenStable();

    const list = menu();
    const children = [...list.children].map((child) => child.getAttribute('role'));

    expect(children).toEqual(['none', 'separator', 'none']);
  });

  it('drops a trailing divider left behind by a hidden item', async () => {
    fixture.componentRef.setInput('items', [
      { linkText: 'First', onClick: () => true },
      { divider: true },
      { linkText: 'Hidden', hidden: true, onClick: () => true },
      { divider: true },
    ]);
    await fixture.whenStable();

    expect([...menu().children].map((child) => child.getAttribute('role'))).toEqual(['none']);
  });

  it('drops a trailing divider left behind by a hidden item in a submenu', async () => {
    fixture.componentRef.setInput('items', [
      {
        linkText: 'Move',
        children: [
          { linkText: 'First', onClick: () => true },
          { divider: true },
          { linkText: 'Hidden', hidden: true, onClick: () => true },
          { divider: true },
        ],
      },
    ]);
    await fixture.whenStable();

    expect([...subMenu().children].map((child) => child.getAttribute('role'))).toEqual(['none']);
  });

  it('keeps focus on an item whose label repeats when the items refresh', async () => {
    const second = { linkText: 'Open', href: '/b', onClick: () => true };
    fixture.componentRef.setInput('items', [{ linkText: 'Open', href: '/a', onClick: () => true }, second]);
    await fixture.whenStable();
    await open();
    within(menu()).getAllByRole('menuitem', { name: 'Open' })[1].focus();

    fixture.componentRef.setInput('items', [{ ...second }]);
    await fixture.whenStable();

    expect(document.activeElement).toHaveAttribute('href', '/b');
  });

  it('keeps the overlay anchored to the invoker without an anchor input', async () => {
    await open();
    fixture.detectChanges();
    await fixture.whenStable();

    expect(fixture.componentInstance.menuElement.overlay).toHaveAttribute('anchor', fixture.componentInstance.invokerId);
  });

  it('anchors the overlay to a given element instead of the invoker', async () => {
    const anchor = document.createElement('div');
    document.body.append(anchor);
    try {
      fixture.componentRef.setInput('anchor', anchor);
      await fixture.whenStable();

      expect((popover() as unknown as { anchorElement:Element|null }).anchorElement).toBe(anchor);
    } finally {
      anchor.remove();
    }
  });

  it('puts the item class on the list item, not the content', async () => {
    await open();
    const link = within(menu()).getByRole('menuitem', { name: 'Link' });

    expect(link).not.toHaveClass('detailsViewMenuItem');
    expect(link.closest('li')).toHaveClass('ActionListItem', 'detailsViewMenuItem');
  });

  it('omits the leading visual slot when an item has no icon', async () => {
    await open();
    const plain = within(menu()).getByRole('menuitem', { name: 'Plain' });

    expect(plain).not.toHaveClass('ActionListContent--visual16');
    expect(plain.querySelector('.ActionListItem-visual--leading')).toBeNull();
  });

  it('end-aligns the overlay when asked', async () => {
    fixture.componentRef.setInput('align', 'end');
    await fixture.whenStable();

    expect(fixture.componentInstance.menuElement.overlay).toHaveAttribute('align', 'end');
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

  it.each(['ArrowRight', 'Enter', ' '])('keeps the submenu of a disabled item closed on %j', async (key) => {
    fixture.componentRef.setInput('items', [{
      linkText: 'Move',
      disabled: true,
      children: [{ linkText: 'Move up', onClick: () => { clicked.push('up'); return true; } }],
    }]);
    await fixture.whenStable();
    await open();
    const trigger = within(menu()).getByRole('menuitem', { name: 'Move' });
    trigger.focus();

    fireEvent.keyDown(trigger, { key });
    await settle();

    expect(subMenu().closest('anchored-position')!.matches(':popover-open')).toBe(false);
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

  it('opens a submenu nested at the same position as its parent submenu', async () => {
    fixture.componentRef.setInput('items', [{
      linkText: 'Move',
      children: [{ linkText: 'More', children: [{ linkText: 'Deep', onClick: () => true }] }],
    }]);
    await fixture.whenStable();
    await open();
    within(menu()).getByRole('menuitem', { name: 'Move' }).focus();
    await userEvent.keyboard('{ArrowRight}');
    await settle();

    await userEvent.keyboard('{ArrowRight}');
    await settle();

    const nested = within(fixture.nativeElement as HTMLElement).getByRole('menu', { name: 'More', hidden: true });
    expect(within(nested).getByRole('menuitem', { name: 'Deep' })).toHaveFocus();
    expect(within(subMenu()).getByRole('menuitem', { name: 'More' })).toBeVisible();
  });
});

@Component({
  imports: [OpActionMenuComponent, OpActionMenuTriggerDirective],
  template: `
    <input aria-label="Elsewhere field">
    <op-action-menu [items]="items" label="Subject menu" align="end" (opening)="opened = opened + 1" (closed)="reasons.push($event)">
      <button opActionMenuTrigger>Subject</button>
    </op-action-menu>
    <op-action-menu [items]="items" label="Status menu" (closed)="reasons.push($event)">
      <button opActionMenuTrigger>Status</button>
    </op-action-menu>
    <button type="button">Elsewhere</button>
    <input aria-label="Dialog field">
  `,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
class TriggerHostComponent {
  opened = 0;

  reasons:OpContextMenuCloseReason[] = [];

  items:OpContextMenuItem[] = [
    { linkText: 'Open', onClick: () => true },
    {
      linkText: 'Open dialog',
      onClick: () => {
        screen.getByRole('textbox', { name: 'Dialog field' }).focus();
        return true;
      },
    },
    { linkText: 'Move', children: [{ linkText: 'Move up', onClick: () => true }] },
  ];
}

describe('OpActionMenuComponent with a projected trigger', () => {
  let fixture:ComponentFixture<TriggerHostComponent>;
  let host:TriggerHostComponent;

  const settle = settlePopover;
  const trigger = () => screen.getByRole('button', { name: 'Subject' });
  const menu = () => screen.getByRole('menu', { name: 'Subject menu', hidden: true });
  const secondMenu = () => screen.getByRole('menu', { name: 'Status menu', hidden: true });
  const menuElement = () => (fixture.nativeElement as HTMLElement).querySelector<ActionMenuElement>('action-menu')!;
  const subMenu = () => within(menu()).getByRole('menu', { name: 'Move', hidden: true });
  // Primer focuses the first item a frame after the toggle task, which Firefox
  // may run after a settle; a key sent before then lands on the wrong item.
  const openWithClick = async () => {
    fireEvent.click(trigger());
    await waitFor(() => expect(menu()).toContainElement(document.activeElement as HTMLElement));
  };
  const openSubMenu = async () => {
    within(menu()).getByRole('menuitem', { name: 'Move' }).focus();
    await userEvent.keyboard('{ArrowRight}');
    await waitFor(() => expect(within(subMenu()).getByRole('menuitem', { name: 'Move up', hidden: true })).toHaveFocus());
  };

  beforeEach(async () => {
    await TestBed.configureTestingModule({ imports: [TriggerHostComponent] }).compileComponents();
    fixture = TestBed.createComponent(TriggerHostComponent);
    host = fixture.componentInstance;
    await fixture.whenStable();
  });

  it('wires the projected button as the menu invoker', () => {
    const button = trigger();

    expect(button).toHaveAttribute('aria-haspopup', 'menu');
    expect(button).toHaveAttribute('aria-expanded', 'false');
    expect(button).toHaveAttribute('aria-controls', menu().id);
    expect(button).toHaveAttribute('popovertarget', menuElement().overlay.id);
    expect(menuElement().overlay).toHaveAttribute('anchor', button.id);
    expect(menuElement().invokerElement).toBe(button);
    expect(screen.queryByRole('button', { name: 'Subject menu' })).toBeNull();
  });

  it('reports opening before the list is read and tracks aria-expanded', async () => {
    await openWithClick();

    expect(host.opened).toBe(1);
    expect(trigger()).toHaveAttribute('aria-expanded', 'true');
    expect(within(menu()).getAllByRole('menuitem')[0]).toHaveFocus();
  });

  it('closes with reason escape and leaves focus on the trigger', async () => {
    await openWithClick();

    fireEvent.keyDown(document.activeElement!, { key: 'Escape' });
    await settle();

    expect(host.reasons).toEqual(['escape']);
    expect(trigger()).toHaveAttribute('aria-expanded', 'false');
    expect(trigger()).toHaveFocus();
  });

  it('closes with reason action when an item activates', async () => {
    await openWithClick();

    fireEvent.click(within(menu()).getByRole('menuitem', { name: 'Open' }));
    await settle();

    expect(host.reasons).toEqual(['action']);
  });

  it('leaves focus in a dialog an action opened', async () => {
    await openWithClick();

    fireEvent.click(within(menu()).getByRole('menuitem', { name: 'Open dialog' }));
    await settle();

    expect(host.reasons).toEqual(['action']);
    expect(screen.getByRole('textbox', { name: 'Dialog field' })).toHaveFocus();
  });

  it('keeps focus on an outside control clicked while open (real pointer)', async () => {
    await openWithClick();

    await userEvent.click(screen.getByRole('textbox', { name: 'Elsewhere field' }));
    await settle();

    expect(host.reasons).toEqual(['outside']);
    expect(screen.getByRole('textbox', { name: 'Elsewhere field' })).toHaveFocus();
  });

  it('keeps focus where Tab moved it (real keyboard)', async () => {
    await openWithClick();

    await userEvent.tab();
    await settle();

    expect(host.reasons).toEqual(['outside']);
    expect(trigger()).not.toHaveFocus();
  });

  it('reports a submenu Escape followed by an outside close as outside (real pointer)', async () => {
    await openWithClick();
    await openSubMenu();

    await userEvent.keyboard('{Escape}');
    await waitFor(() => expect(subMenu().closest('anchored-position')!.matches(':popover-open')).toBe(false));
    expect(host.reasons).toEqual([]);

    await userEvent.click(screen.getByRole('button', { name: 'Elsewhere' }));
    await settle();

    expect(host.reasons).toEqual(['outside']);
  });

  it('hands focus to a second menu opened while the first is open (real pointer)', async () => {
    await openWithClick();

    await userEvent.click(screen.getByRole('button', { name: 'Status' }));
    await settle();

    expect(host.reasons).toEqual(['outside']);
    expect(within(secondMenu()).getAllByRole('menuitem')[0]).toHaveFocus();
  });
});

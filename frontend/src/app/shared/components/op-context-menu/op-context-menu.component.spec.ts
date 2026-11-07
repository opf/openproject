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

import { A11yModule } from '@angular/cdk/a11y';
import { PortalModule } from '@angular/cdk/portal';
import { OpModalOverlayComponent } from '../modal/modal-overlay.component';
import { ConfirmDialogService } from '../modals/confirm-dialog/confirm-dialog.service';
import { ConfirmDialogModalComponent } from '../modals/confirm-dialog/confirm-dialog.modal';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { CommonModule } from '@angular/common';
import { OpIconComponent } from 'core-app/shared/components/icon/icon.component';
import { NO_ERRORS_SCHEMA } from '@angular/core';
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { screen } from '@testing-library/dom';
import { OpTooltipDirective } from 'core-app/shared/components/primer/tooltip.directive';
import { OPContextMenuComponent } from './op-context-menu.component';
import { OpContextMenuItem, OpContextMenuLocalsToken } from './op-context-menu.types';

describe('OPContextMenuComponent', () => {
  let fixture:ComponentFixture<OPContextMenuComponent>;

  const items:OpContextMenuItem[] = [
    { linkText: 'Cards', title: 'Show card view', onClick: () => true },
    { linkText: 'Table', href: '/table', title: 'Show table view', onClick: () => true },
    { linkText: 'Gantt', ariaLabel: 'Gantt chart', disabled: true, onClick: () => true },
  ];

  const menuitem = (name:string) => screen.getByRole('menuitem', { name });

  beforeEach(async () => {
    await TestBed
      .configureTestingModule({
        imports: [OpTooltipDirective],
        declarations: [OPContextMenuComponent],
        schemas: [NO_ERRORS_SCHEMA],
        providers: [
          { provide: OpContextMenuLocalsToken, useValue: { items, label: 'View', service: {} } },
        ],
      })
      .compileComponents();

    fixture = TestBed.createComponent(OPContextMenuComponent);
    fixture.detectChanges();
    (fixture.nativeElement as HTMLElement).querySelector<HTMLElement>('.dropdown')!.style.visibility = 'visible';
    await fixture.whenStable();
  });

  it('describes menu items by their title through a tooltip', () => {
    expect(menuitem('Cards')).toHaveAccessibleDescription('Show card view');
    expect(menuitem('Table')).toHaveAccessibleDescription('Show table view');
  });

  it('keeps the aria-label and aria-disabled of items without a title', () => {
    const gantt = menuitem('Gantt chart');

    expect(gantt).toHaveAttribute('aria-disabled', 'true');
    expect(gantt).not.toHaveAccessibleDescription();
  });

  it('keeps each tooltip inside the list item of its menu item', () => {
    const listItems = screen.getAllByRole('menuitem').map((item) => item.parentElement);

    expect(listItems.map((li) => li?.tagName)).toEqual(['LI', 'LI', 'LI']);
    expect(listItems.map((li) => li?.querySelectorAll('tool-tip').length)).toEqual([1, 1, 0]);
  });
});

describe('OPContextMenuComponent actions', () => {
  it('renders visible menu items and invokes their actions', async () => {
    const close = vi.fn();
    const onClick = vi.fn().mockReturnValue(true);
    TestBed.configureTestingModule({
      declarations: [OPContextMenuComponent, OpIconComponent],
      imports: [CommonModule, OpTooltipDirective],
      providers: [{
        provide: OpContextMenuLocalsToken,
        useValue: {
          items: [{ linkText: 'Open', onClick }, { linkText: 'Hidden', hidden: true }],
          service: { close },
        },
      }],
    });
    const fixture = TestBed.createComponent(OPContextMenuComponent);
    await fixture.whenStable();
    const element = fixture.nativeElement as HTMLElement;
    expect(element).toHaveTextContent('Open');
    expect(element).not.toHaveTextContent('Hidden');
    element.querySelector('button')!.click();
    expect(onClick).toHaveBeenCalled();
    expect(close).toHaveBeenCalledWith(false, 'action');
  });
});

describe('OPContextMenuComponent confirmation', () => {
  it('keeps the confirmation dialog open after choosing a menu action', async () => {
    const changed = vi.fn();
    TestBed.configureTestingModule({
      imports: [CommonModule, A11yModule, PortalModule, OpTooltipDirective],
      declarations: [OPContextMenuComponent, OpIconComponent, OpModalOverlayComponent, ConfirmDialogModalComponent],
      schemas: [NO_ERRORS_SCHEMA],
      providers: [
        ConfirmDialogService,
        { provide: I18nService, useValue: { t: (key:string) => key } },
        { provide: OpContextMenuLocalsToken, useValue: {
          items: [{ linkText: 'Sort ascending', onClick: () => {
            const confirm = TestBed.inject(ConfirmDialogService);
            void confirm.confirm({ text: { title: 'Change sorting', text: 'Manual order will be lost' } }).then(changed);
            return false;
          } }],
          service: { close: vi.fn() },
        } },
      ],
    });
    const overlay = TestBed.createComponent(OpModalOverlayComponent);
    const menu = TestBed.createComponent(OPContextMenuComponent);
    await overlay.whenStable();
    await menu.whenStable();
    (menu.nativeElement as HTMLElement).querySelector('button')!.click();
    await overlay.whenStable();
    const dialog = (overlay.nativeElement as HTMLElement).querySelector('.spot-modal');
    expect(dialog).not.toBeNull();
    expect(dialog).toHaveTextContent('Manual order will be lost');
    expect(changed).not.toHaveBeenCalled();
    dialog?.querySelector<HTMLButtonElement>('[data-test-selector="confirmation-modal--confirmed"]')?.click();
    await overlay.whenStable();
    expect(changed).toHaveBeenCalledOnce();
  });
});

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

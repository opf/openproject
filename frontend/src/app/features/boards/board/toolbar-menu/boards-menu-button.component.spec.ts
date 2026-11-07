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
import { TestBed } from '@angular/core/testing';
import { screen } from '@testing-library/dom';
import { OpTooltipDirective } from 'core-app/shared/components/primer/tooltip.directive';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { BoardsMenuButtonComponent } from './boards-menu-button.component';

describe('BoardsMenuButtonComponent', () => {
  it('labels the icon-only button with its tooltip', async () => {
    await TestBed
      .configureTestingModule({
        imports: [OpTooltipDirective],
        declarations: [BoardsMenuButtonComponent],
        providers: [
          { provide: I18nService, useValue: { t: (key:string) => key } },
        ],
        schemas: [NO_ERRORS_SCHEMA],
      })
      .compileComponents();

    const fixture = TestBed.createComponent(BoardsMenuButtonComponent);
    fixture.detectChanges();
    await fixture.whenStable();

    const button = screen.getByRole('button');

    expect(button).toHaveAccessibleName('js.button_more');
    expect(button.nextElementSibling).toHaveAttribute('for', button.id);
  });
});

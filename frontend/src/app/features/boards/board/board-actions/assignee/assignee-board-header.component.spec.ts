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

import { CUSTOM_ELEMENTS_SCHEMA } from '@angular/core';
import { CommonModule } from '@angular/common';
import { TestBed } from '@angular/core/testing';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { AssigneeBoardHeaderComponent } from './assignee-board-header.component';

describe('AssigneeBoardHeaderComponent', () => {
  it('renders resource changes after the initial render', async () => {
    TestBed.configureTestingModule({
      declarations: [AssigneeBoardHeaderComponent],
      imports: [CommonModule],
      schemas: [CUSTOM_ELEMENTS_SCHEMA],
      providers: [
        { provide: I18nService, useValue: { t: (key:string) => key } satisfies Pick<I18nService, 't'> },
        { provide: PathHelperService, useValue: {
          userPath: (id) => `/users/${id}`,
        } satisfies Pick<PathHelperService, 'userPath'> },
      ],
    });
    const fixture = TestBed.createComponent(AssigneeBoardHeaderComponent);
    fixture.componentRef.setInput('resource', { name: 'Unassigned' });
    await fixture.whenStable();
    expect(fixture.nativeElement as HTMLElement).toHaveTextContent('Unassigned');

    fixture.componentRef.setInput('resource', { id: '2', name: 'Alex' });
    await fixture.whenStable();
    expect(fixture.nativeElement as HTMLElement).toHaveTextContent('Alex');
    expect(fixture.nativeElement as HTMLElement).not.toHaveTextContent('Unassigned');
    expect((fixture.nativeElement as HTMLElement).querySelector('a')).toHaveAttribute('href', '/users/2');
  });
});

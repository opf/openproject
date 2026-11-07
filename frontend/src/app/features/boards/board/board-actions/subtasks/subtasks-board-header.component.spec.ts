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

import { CommonModule } from '@angular/common';
import { TestBed } from '@angular/core/testing';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { SubtasksBoardHeaderComponent } from './subtasks-board-header.component';

describe('SubtasksBoardHeaderComponent', () => {
  it('renders resource changes after the initial render', async () => {
    TestBed.configureTestingModule({
      declarations: [SubtasksBoardHeaderComponent],
      imports: [CommonModule],
      providers: [
        { provide: I18nService, useValue: { t: (key:string) => key } satisfies Pick<I18nService, 't'> },
        { provide: PathHelperService, useValue: {
          workPackagePath: (id) => `/work_packages/${id}`,
        } satisfies Pick<PathHelperService, 'workPackagePath'> },
      ],
    });
    const fixture = TestBed.createComponent(SubtasksBoardHeaderComponent);
    fixture.componentRef.setInput('resource', { href: '/api/v3/work_packages/1', type: { id: '1', name: 'Task' }, subjectWithId: () => 'Parent task' });
    await fixture.whenStable();
    expect(fixture.nativeElement as HTMLElement).toHaveTextContent('Parent task');

    fixture.componentRef.setInput('resource', { href: '/api/v3/work_packages/2', type: { id: '1', name: 'Task' }, subjectWithId: () => 'Another task' });
    await fixture.whenStable();
    expect(fixture.nativeElement as HTMLElement).toHaveTextContent('Another task');
    expect(fixture.nativeElement as HTMLElement).not.toHaveTextContent('Parent task');
    expect((fixture.nativeElement as HTMLElement).querySelector('a')).toHaveAttribute('href', '/work_packages/2');
  });
});

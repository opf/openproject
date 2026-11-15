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
import { SubprojectBoardHeaderComponent } from './subproject-board-header.component';

describe('SubprojectBoardHeaderComponent', () => {
  it('renders resource changes after the initial render', async () => {
    TestBed.configureTestingModule({
      declarations: [SubprojectBoardHeaderComponent],
      imports: [CommonModule],
      providers: [
        { provide: I18nService, useValue: { t: (key:string) => key } satisfies Pick<I18nService, 't'> },
        { provide: PathHelperService, useValue: {
          projectPath: (id) => `/projects/${id}`,
        } satisfies Pick<PathHelperService, 'projectPath'> },
      ],
    });
    const fixture = TestBed.createComponent(SubprojectBoardHeaderComponent);
    fixture.componentRef.setInput('resource', { href: '/api/v3/projects/1', name: 'Child project' });
    await fixture.whenStable();
    expect(fixture.nativeElement as HTMLElement).toHaveTextContent('Child project');

    fixture.componentRef.setInput('resource', { href: '/api/v3/projects/2', name: 'Another project' });
    await fixture.whenStable();
    expect(fixture.nativeElement as HTMLElement).toHaveTextContent('Another project');
    expect(fixture.nativeElement as HTMLElement).not.toHaveTextContent('Child project');
    expect((fixture.nativeElement as HTMLElement).querySelector('a')).toHaveAttribute('href', '/projects/2');
  });
});

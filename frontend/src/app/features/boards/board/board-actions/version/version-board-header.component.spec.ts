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
import { VersionBoardHeaderComponent } from './version-board-header.component';

describe('VersionBoardHeaderComponent', () => {
  it('renders resource changes after the initial render', async () => {
    TestBed.configureTestingModule({
      declarations: [VersionBoardHeaderComponent],
      imports: [CommonModule],
      providers: [
        { provide: I18nService, useValue: { t: (key:string) => key } satisfies Pick<I18nService, 't'> },
        { provide: PathHelperService, useValue: {
          versionShowPath: (id) => `/versions/${id}`,
        } satisfies Pick<PathHelperService, 'versionShowPath'> },
      ],
    });
    const fixture = TestBed.createComponent(VersionBoardHeaderComponent);
    fixture.componentRef.setInput('resource', { id: '1', name: 'Release', endDate: '2026-11-07', isClosed: () => false, isLocked: () => false });
    await fixture.whenStable();
    expect(fixture.nativeElement as HTMLElement).toHaveTextContent('Release');

    fixture.componentRef.setInput('resource', { id: '2', name: 'Next version', endDate: '2026-12-01', isClosed: () => true, isLocked: () => false });
    await fixture.whenStable();
    expect(fixture.nativeElement as HTMLElement).toHaveTextContent('Next version');
    expect(fixture.nativeElement as HTMLElement).not.toHaveTextContent('Release');
    expect((fixture.nativeElement as HTMLElement).querySelector('a')).toHaveAttribute('href', '/versions/2');
    expect((fixture.nativeElement as HTMLElement).querySelector('.op-version-board-header')).toHaveClass('-closed');
  });
});

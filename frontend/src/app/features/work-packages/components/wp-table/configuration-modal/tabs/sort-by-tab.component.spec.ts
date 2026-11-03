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

import { TestBed } from '@angular/core/testing';
import { FormsModule } from '@angular/forms';
import { NEVER } from 'rxjs';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { WorkPackageViewSortByService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-sort-by.service';
import { SortModalObject, WpTableConfigurationSortByTabComponent } from './sort-by-tab.component';

describe('WpTableConfigurationSortByTabComponent', () => {
  it('labels each sort criterion select with its own position', async () => {
    await TestBed.configureTestingModule({
      imports: [FormsModule],
      declarations: [WpTableConfigurationSortByTabComponent],
      providers: [
        { provide: I18nService, useValue: { t: (key:string) => key } },
        { provide: WorkPackageViewSortByService, useValue: { onReadyWithAvailable: () => NEVER } },
      ],
    }).compileComponents();
    const fixture = TestBed.createComponent(WpTableConfigurationSortByTabComponent);
    fixture.componentInstance.sortationObjects = [0, 1, 2].map(() => new SortModalObject({ name: '-', href: null }, ''));
    fixture.detectChanges();

    const labels = Array.from((fixture.nativeElement as HTMLElement).querySelectorAll('label.sr-only'), label => label.textContent);
    expect(labels).toEqual([
      'js.filter.sorting.criteria.one',
      'js.filter.sorting.criteria.two',
      'js.filter.sorting.criteria.three',
    ]);
  });
});

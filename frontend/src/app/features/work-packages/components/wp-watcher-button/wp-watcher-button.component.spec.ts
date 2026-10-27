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
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { screen, waitFor } from '@testing-library/dom';
import { Subject } from 'rxjs';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { OpTooltipDirective } from 'core-app/shared/components/primer/tooltip.directive';
import {
  WorkPackageWatchersService,
} from 'core-app/features/work-packages/components/wp-single-view-tabs/watchers-tab/wp-watchers.service';
import { WorkPackageWatcherButtonComponent } from './wp-watcher-button.component';

const translations:Record<string, string> = {
  'js.label_watch_work_package': 'Watch work package',
  'js.label_unwatch_work_package': 'Unwatch work package',
};

describe('WorkPackageWatcherButtonComponent', () => {
  let fixture:ComponentFixture<WorkPackageWatcherButtonComponent>;
  let workPackage$:Subject<WorkPackageResource>;

  const workPackageWith = (link:'watch'|'unwatch') => ({ id: '1', [link]: {} }) as unknown as WorkPackageResource;

  beforeEach(async () => {
    workPackage$ = new Subject();

    await TestBed
      .configureTestingModule({
        imports: [CommonModule, OpTooltipDirective],
        declarations: [WorkPackageWatcherButtonComponent],
        providers: [
          { provide: I18nService, useValue: { t: (key:string) => translations[key] } },
          { provide: WorkPackageWatchersService, useValue: { clear: vi.fn() } },
          {
            provide: ApiV3Service,
            useValue: { work_packages: { id: () => ({ requireAndStream: () => workPackage$, refresh: vi.fn() }) } },
          },
        ],
      })
      .compileComponents();

    fixture = TestBed.createComponent(WorkPackageWatcherButtonComponent);
    fixture.componentRef.setInput('workPackage', workPackageWith('watch'));
    fixture.detectChanges();
  });

  afterEach(() => {
    fixture.destroy();
  });

  it('points the tooltip at the current button id when the watch state flips', async () => {
    workPackage$.next(workPackageWith('watch'));
    await fixture.whenStable();

    let button = screen.getByRole('button', { name: 'Watch work package' });
    expect(button).toHaveAttribute('id', 'watch-button');
    expect(screen.getByText('Watch work package', { selector: 'tool-tip' })).toHaveAttribute('for', 'watch-button');

    workPackage$.next(workPackageWith('unwatch'));
    await fixture.whenStable();

    button = screen.getByRole('button', { name: 'Unwatch work package' });
    expect(button).toHaveAttribute('id', 'unwatch-button');
    await waitFor(() => {
      expect(screen.getByText('Unwatch work package', { selector: 'tool-tip' })).toHaveAttribute('for', 'unwatch-button');
    });
    expect(document.querySelectorAll('tool-tip')).toHaveLength(1);
  });
});

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

import { ChangeDetectionStrategy, Component, Input } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { Subject } from 'rxjs';
import { GridResource } from 'core-app/features/hal/resources/grid-resource';
import { GridInitializationService } from 'core-app/shared/components/grids/grid/initialization.service';
import { GridAreaService } from 'core-app/shared/components/grids/grid/area.service';
import { GridAddWidgetService } from 'core-app/shared/components/grids/grid/add-widget.service';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { CurrentProjectService } from 'core-app/core/current-project/current-project.service';
import { ConfigurationService } from 'core-app/core/config/configuration.service';
import { MyPageComponent } from './my-page.component';

@Component({
  // eslint-disable-next-line @angular-eslint/component-selector
  selector: 'grid',
  template: '{{ grid.rowCount }} rows',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
class GridStubComponent {
  @Input({ required: true }) grid:GridResource;
}

describe('MyPageComponent', () => {
  it('renders asynchronously loaded grids and unsubscribes on destruction', async () => {
    const grids = new Subject<GridResource>();
    const initialize = vi.fn<GridInitializationService['initialize']>(() => grids);
    TestBed.configureTestingModule({
      declarations: [MyPageComponent],
      imports: [GridStubComponent],
      providers: [
        { provide: GridInitializationService, useValue: { initialize } },
        { provide: GridAreaService, useValue: {} },
        { provide: GridAddWidgetService, useValue: {} },
        { provide: PathHelperService, useValue: { myPagePath: () => '/grid' } satisfies Pick<PathHelperService, 'myPagePath'> },
        { provide: CurrentProjectService, useValue: {} },
        { provide: ConfigurationService, useValue: {} },
      ],
    }).overrideComponent(MyPageComponent, { set: { providers: [] } });
    const fixture = TestBed.createComponent(MyPageComponent);
    await fixture.whenStable();
    expect(initialize).toHaveBeenCalledWith('/grid');
    expect((fixture.nativeElement as HTMLElement).querySelector('grid')).toBeNull();
    grids.next({ rowCount: 2 } as GridResource);
    await fixture.whenStable();
    expect(fixture.nativeElement as HTMLElement).toHaveTextContent('2 rows');
    grids.next({ rowCount: 3 } as GridResource);
    await fixture.whenStable();
    expect(fixture.nativeElement as HTMLElement).toHaveTextContent('3 rows');
    expect(document.body).toHaveClass('widget-grid-layout');
    fixture.destroy();
    expect(grids.observed).toBe(false);
    expect(document.body).not.toHaveClass('widget-grid-layout');
  });
});

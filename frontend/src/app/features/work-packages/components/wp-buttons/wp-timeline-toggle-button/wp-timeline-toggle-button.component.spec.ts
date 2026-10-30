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
import { fireEvent, screen } from '@testing-library/dom';
import { BehaviorSubject } from 'rxjs';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { TimelineZoomLevel } from 'core-app/features/hal/resources/query-resource';
import { OpIconComponent } from 'core-app/shared/components/icon/icon.component';
import { OpTooltipDirective } from 'core-app/shared/components/primer/tooltip.directive';
import {
  WorkPackageViewTimelineService,
} from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-timeline.service';
import { WorkPackageTimelineButtonComponent } from './wp-timeline-toggle-button.component';

const translations:Record<string, string> = {
  'js.gantt_chart.zoom.in': 'Zoom in',
  'js.gantt_chart.zoom.out': 'Zoom out',
  'js.gantt_chart.zoom.auto': 'Auto zoom',
};

describe('WorkPackageTimelineButtonComponent', () => {
  let fixture:ComponentFixture<WorkPackageTimelineButtonComponent>;
  let zoomLevel$:BehaviorSubject<TimelineZoomLevel>;
  let timeline:{ updateZoomWithDelta:ReturnType<typeof vi.fn> };

  async function renderAt(level:TimelineZoomLevel) {
    zoomLevel$.next(level);
    fixture = TestBed.createComponent(WorkPackageTimelineButtonComponent);
    fixture.detectChanges();
    await fixture.whenStable();
  }

  beforeEach(async () => {
    zoomLevel$ = new BehaviorSubject<TimelineZoomLevel>('weeks');
    timeline = { updateZoomWithDelta: vi.fn() };

    await TestBed
      .configureTestingModule({
        imports: [CommonModule, OpTooltipDirective],
        declarations: [WorkPackageTimelineButtonComponent, OpIconComponent],
        providers: [
          { provide: I18nService, useValue: { t: (key:string) => translations[key] ?? key } },
          {
            provide: WorkPackageViewTimelineService,
            useValue: {
              ...timeline,
              isVisible: true,
              isAutoZoom: () => false,
              live$: () => new BehaviorSubject(null),
              appliedZoomLevel$: { values$: () => zoomLevel$ },
            },
          },
        ],
      })
      .compileComponents();
  });

  afterEach(() => {
    fixture.destroy();
  });

  it('does not zoom out past the widest level', async () => {
    await renderAt('years');

    const zoomOut = screen.getByRole('button', { name: 'Zoom out' });
    expect(zoomOut).toHaveAttribute('aria-disabled', 'true');

    fireEvent.click(zoomOut);
    expect(timeline.updateZoomWithDelta).not.toHaveBeenCalled();

    fireEvent.click(screen.getByRole('button', { name: 'Zoom in' }));
    expect(timeline.updateZoomWithDelta).toHaveBeenCalledWith(-1);
  });

  it('does not zoom in past the narrowest level', async () => {
    await renderAt('days');

    const zoomIn = screen.getByRole('button', { name: 'Zoom in' });
    expect(zoomIn).toHaveAttribute('aria-disabled', 'true');

    fireEvent.click(zoomIn);
    expect(timeline.updateZoomWithDelta).not.toHaveBeenCalled();

    fireEvent.click(screen.getByRole('button', { name: 'Zoom out' }));
    expect(timeline.updateZoomWithDelta).toHaveBeenCalledWith(1);
  });
});

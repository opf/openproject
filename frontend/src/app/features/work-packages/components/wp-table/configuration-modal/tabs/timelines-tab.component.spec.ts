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
import { fireEvent, within } from '@testing-library/dom';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { WorkPackageViewTimelineService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-timeline.service';
import { WorkPackageViewColumnsService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-columns.service';
import { WpTableConfigurationTimelinesTabComponent } from './timelines-tab.component';

describe('WpTableConfigurationTimelinesTabComponent', () => {
  async function render(visible = true) {
    const labels = { left: 'subject', right: null, farRight: null };
    const timeline = {
      isVisible: visible,
      zoomLevel: 'auto',
      labels,
      current: { visible, zoomLevel: 'auto', labels },
      update: vi.fn<WorkPackageViewTimelineService['update']>(),
    } satisfies Pick<WorkPackageViewTimelineService, 'isVisible'|'zoomLevel'|'labels'|'current'|'update'>;
    await TestBed.configureTestingModule({
      declarations: [WpTableConfigurationTimelinesTabComponent],
      providers: [
        { provide: I18nService, useValue: { t: (key:string) => key } },
        { provide: WorkPackageViewTimelineService, useValue: timeline },
        { provide: WorkPackageViewColumnsService, useValue: { allPropertyColumns: [{ id: 'subject', name: 'Subject' }] } },
      ],
    }).compileComponents();
    const fixture = TestBed.createComponent(WpTableConfigurationTimelinesTabComponent);
    await fixture.whenStable();
    return { fixture, view: within(fixture.nativeElement as HTMLElement), timeline };
  }

  it('renders the saved zoom and label selections', async () => {
    const { view } = await render();
    expect(view.getByRole('checkbox')).toBeChecked();
    expect(view.getAllByRole('combobox')[0]).toHaveValue('auto');
    expect(view.getByLabelText('js.gantt_chart.labels.left')).toHaveValue('subject');
  });

  it('shows and hides settings when toggled and saves visibility', async () => {
    const { fixture, view, timeline } = await render(false);
    expect(view.queryByRole('combobox')).not.toBeInTheDocument();

    fireEvent.click(view.getByRole('checkbox'));
    await fixture.whenStable();
    expect(view.getAllByRole('combobox')).toHaveLength(4);

    fireEvent.click(view.getByRole('checkbox'));
    await fixture.whenStable();
    expect(view.queryByRole('combobox')).not.toBeInTheDocument();
    fixture.componentInstance.onSave();
    expect(timeline.update).toHaveBeenCalledWith({ ...timeline.current, visible: false });
  });

  it('saves edited zoom and labels without changing live labels before applying', async () => {
    const { fixture, view, timeline } = await render();
    fireEvent.change(view.getAllByRole('combobox')[0], { target: { value: 'weeks' } });
    fireEvent.change(view.getByLabelText('js.gantt_chart.labels.left'), { target: { value: '' } });
    fireEvent.change(view.getByLabelText('js.gantt_chart.labels.right'), { target: { value: 'subject' } });
    await fixture.whenStable();

    expect(view.getAllByRole('combobox')[0]).toHaveValue('weeks');
    expect(view.getByLabelText('js.gantt_chart.labels.left')).toHaveValue('');
    expect(view.getByLabelText('js.gantt_chart.labels.right')).toHaveValue('subject');
    expect(timeline.labels).toEqual({ left: 'subject', right: null, farRight: null });
    expect(timeline.update).not.toHaveBeenCalled();
    fixture.componentInstance.onSave();
    expect(timeline.update).toHaveBeenCalledWith({
      visible: true, zoomLevel: 'weeks', labels: { left: null, right: 'subject', farRight: null },
    });
  });
});

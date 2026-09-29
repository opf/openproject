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
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import '@openproject/primer-view-components/app/components/primer/anchored_position';
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { provideCharts, withDefaultRegisterables } from 'ng2-charts';
import { within } from '@testing-library/dom';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import PrimerColorsPlugin from 'core-app/shared/components/work-package-graphs/plugin.primer-colors';
import { ActualCostsComponent } from './actual-costs.component';
import type { BarTooltipContext } from '../chart.config';

describe('ActualCostsComponent', () => {
  let fixture:ComponentFixture<ActualCostsComponent>;
  let element:HTMLElement;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [ActualCostsComponent],
      providers: [
        { provide: I18nService, useValue: {} },
        provideCharts(withDefaultRegisterables(PrimerColorsPlugin)),
      ],
    }).compileComponents();

    fixture = TestBed.createComponent(ActualCostsComponent);
    element = fixture.nativeElement as HTMLElement;
  });

  const renderWith = (datasets:unknown[]) => {
    fixture.componentRef.setInput('chartData', JSON.stringify({ labels: ['Labour'], datasets }));
    fixture.detectChanges();
  };

  const tooltipContext = (opacity:number):BarTooltipContext => ({
    chart: { canvas: element.querySelector('canvas')! },
    tooltip: {
      opacity,
      caretX: 50,
      caretY: 40,
      dataPoints: [{ parsed: { x: 0, y: 10 }, dataset: { label: 'Labour' }, element: { getProps: () => ({ x: 50, y: 20, base: 120, width: 30 }) } }],
      labelColors: [{ backgroundColor: '#123456' }],
    },
  } as unknown as BarTooltipContext);

  it('renders the chart with a tooltip host beside the canvas', () => {
    renderWith([{ label: 'Labour', data: [10] }]);

    const canvas = element.querySelector('canvas')!;
    expect(canvas).not.toBeNull();
    expect(canvas.nextElementSibling?.tagName).toBe('DIV');
  });

  it('renders nothing without data', () => {
    renderWith([]);
    expect(element.querySelector('canvas')).toBeNull();
  });

  it('drops the tooltip renderer together with its host', () => {
    renderWith([{ label: 'Labour', data: [10] }]);
    const removeListener = vi.spyOn(document, 'removeEventListener');

    renderWith([]);
    expect(removeListener).toHaveBeenCalledWith('scroll', expect.any(Function), expect.anything());

    removeListener.mockClear();
    renderWith([{ label: 'Labour', data: [10] }]);
    fixture.destroy();
    expect(removeListener).toHaveBeenCalledWith('scroll', expect.any(Function), expect.anything());
  });

  it('opens the tooltip inside its host from the Chart.js callback', () => {
    renderWith([{ label: 'Labour', data: [10] }]);
    const external = fixture.componentInstance.barChartOptions()!.plugins!.tooltip!.external as (context:BarTooltipContext) => void;

    external(tooltipContext(1));

    const popover = element.querySelector<HTMLElement>('anchored-position')!;
    expect(popover.matches(':popover-open')).toBe(true);
    expect(within(popover).getByText('Labour')).toBeInTheDocument();
    expect(document.body.querySelector(':scope > anchored-position')).toBeNull();
  });
});

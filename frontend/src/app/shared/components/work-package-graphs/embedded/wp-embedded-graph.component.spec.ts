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
import { I18nService } from 'core-app/core/i18n/i18n.service';
import {
  WorkPackageEmbeddedGraphComponent,
  WorkPackageEmbeddedGraphDataset,
} from 'core-app/shared/components/work-package-graphs/embedded/wp-embedded-graph.component';

describe('WorkPackageEmbeddedGraphComponent', () => {
  const i18nStub = {
    t(key:string, options:Record<string, string> = {}) {
      const translations:Record<string, string> = {
        'js.chart.types.bar': 'Bar',
        'js.grid.widgets.work_packages_graph.summary': `${options.chartType} chart showing work packages which are ${options.description}.`,
        'js.grid.widgets.work_packages_graph.title': 'Work packages graph',
        'js.work_packages.no_results.title': 'No results',
      };

      return translations[key] ?? key;
    },
  };

  const dataset = (label:string, count:number):WorkPackageEmbeddedGraphDataset => ({
    label,
    queryProps: {},
    groups: [{
      count,
      value: 'Open',
      index: 0,
      identifier: 'open',
      sums: {},
      href: [],
      _links: {
        valueLink: [],
        groupBy: { href: '' },
      },
    }],
  });

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [WorkPackageEmbeddedGraphComponent],
      providers: [
        { provide: I18nService, useValue: i18nStub },
      ],
    }).compileComponents();
  });

  const renderGraph = (datasets:WorkPackageEmbeddedGraphDataset[]) => {
    const fixture = TestBed.createComponent(WorkPackageEmbeddedGraphComponent);
    const element = fixture.nativeElement as HTMLElement;

    fixture.componentRef.setInput('datasets', datasets);
    fixture.detectChanges();

    return { fixture, element };
  };

  it('provides a translated name and detailed description for the chart', () => {
    const { element } = renderGraph([dataset('All work packages', 2)]);

    const canvas = element.querySelector('canvas')!;
    const descriptionId = canvas.getAttribute('aria-describedby')!;
    const description = element.querySelector<HTMLElement>(`#${descriptionId}`)!;

    expect(canvas).toHaveAttribute('role', 'img');
    expect(canvas).toHaveAccessibleName('Work packages graph');
    expect(description).not.toBeVisible();
    expect(description).toHaveTextContent('Bar chart showing work packages which are 2 Open.');
    expect(canvas).toHaveTextContent('2 Open');
  });

  it('uses a unique description ID for each graph', () => {
    const first = renderGraph([dataset('First query', 2)]);
    const second = renderGraph([dataset('Second query', 3)]);
    document.body.append(first.element, second.element);

    const firstCanvas = first.element.querySelector('canvas')!;
    const secondCanvas = second.element.querySelector('canvas')!;
    const firstDescriptionId = firstCanvas.getAttribute('aria-describedby');
    const secondDescriptionId = secondCanvas.getAttribute('aria-describedby');

    expect(firstDescriptionId).toEqual(first.fixture.componentInstance.chartDescriptionId);
    expect(secondDescriptionId).toEqual(second.fixture.componentInstance.chartDescriptionId);
    expect(firstDescriptionId).not.toEqual(secondDescriptionId);
    expect(firstCanvas).toHaveAccessibleDescription('Bar chart showing work packages which are 2 Open.');
    expect(secondCanvas).toHaveAccessibleDescription('Bar chart showing work packages which are 3 Open.');
  });

  it('describes values from multiple datasets', () => {
    const { fixture } = renderGraph([dataset('First query', 2), dataset('Second query', 3)]);

    expect(fixture.componentInstance.chartDescription).toEqual('Open: 2 First query, 3 Second query');
  });

  it('does not render chart semantics without data', () => {
    const { fixture, element } = renderGraph([]);

    expect(element.querySelector('canvas')).toBeNull();
    expect(element.querySelector(`#${fixture.componentInstance.chartDescriptionId}`)).toBeNull();
  });
});

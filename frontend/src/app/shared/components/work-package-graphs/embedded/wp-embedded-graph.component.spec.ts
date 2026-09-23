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

import { ComponentFixture, TestBed } from '@angular/core/testing';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import {
  WorkPackageEmbeddedGraphComponent,
  WorkPackageEmbeddedGraphDataset,
} from 'core-app/shared/components/work-package-graphs/embedded/wp-embedded-graph.component';

describe('WorkPackageEmbeddedGraphComponent', () => {
  let fixture:ComponentFixture<WorkPackageEmbeddedGraphComponent>;
  let element:HTMLElement;

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

    fixture = TestBed.createComponent(WorkPackageEmbeddedGraphComponent);
    element = fixture.nativeElement as HTMLElement;
  });

  const renderWith = (datasets:WorkPackageEmbeddedGraphDataset[]) => {
    fixture.componentRef.setInput('datasets', datasets);
    fixture.detectChanges();
  };

  it('provides a translated name and detailed description for the chart', () => {
    renderWith([dataset('All work packages', 2)]);

    const canvas = element.querySelector('canvas')!;
    const descriptionId = canvas.getAttribute('aria-describedby')!;
    const description = element.querySelector<HTMLElement>(`#${descriptionId}`)!;

    expect(canvas.getAttribute('role')).toEqual('img');
    expect(canvas.getAttribute('aria-label')).toEqual('Work packages graph');
    expect(description.hidden).toBe(true);
    expect(description.textContent?.trim()).toEqual('Bar chart showing work packages which are 2 Open.');
    expect(canvas.textContent?.trim()).toEqual('2 Open');
  });

  it('uses a unique description ID for each graph', () => {
    renderWith([dataset('First query', 2)]);
    const secondFixture = TestBed.createComponent(WorkPackageEmbeddedGraphComponent);
    const secondElement = secondFixture.nativeElement as HTMLElement;

    secondFixture.componentRef.setInput('datasets', [dataset('Second query', 3)]);
    secondFixture.detectChanges();

    const firstDescriptionId = element.querySelector('canvas')!.getAttribute('aria-describedby');
    const secondDescriptionId = secondElement.querySelector('canvas')!.getAttribute('aria-describedby');

    expect(firstDescriptionId).toEqual(fixture.componentInstance.chartDescriptionId);
    expect(secondDescriptionId).toEqual(secondFixture.componentInstance.chartDescriptionId);
    expect(firstDescriptionId).not.toEqual(secondDescriptionId);
  });

  it('describes values from multiple datasets', () => {
    renderWith([dataset('First query', 2), dataset('Second query', 3)]);

    expect(fixture.componentInstance.chartDescription).toEqual('Open: 2 First query, 3 Second query');
  });

  it('does not render chart semantics without data', () => {
    renderWith([]);

    expect(element.querySelector('canvas')).toBeNull();
    expect(element.querySelector(`#${fixture.componentInstance.chartDescriptionId}`)).toBeNull();
  });
});

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

import { ComponentFixture, TestBed } from '@angular/core/testing';
import { screen } from '@testing-library/dom';
import { graphIconData, noteIconData } from '@openproject/octicons-angular';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { DynamicIconName } from 'core-app/shared/components/primer/dynamic-icon-map';
import { BlankslateHeadingLevel } from './blankslate.component';
import { NoResultsComponent } from './no-results.component';

describe('NoResultsComponent', () => {
  const I18nStub = {
    t(key:string) {
      return { 'js.label_no_data': 'No data to display' }[key] ?? key;
    },
  };

  let fixture:ComponentFixture<NoResultsComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [NoResultsComponent],
      providers: [{ provide: I18nService, useValue: I18nStub }],
    }).compileComponents();

    fixture = TestBed.createComponent(NoResultsComponent);
    document.body.appendChild(fixture.nativeElement as HTMLElement);
  });

  afterEach(() => {
    fixture.destroy();
  });

  function render(inputs:{ icon?:DynamicIconName, title?:string, message?:string, headingLevel?:BlankslateHeadingLevel } = {}):void {
    Object.entries(inputs).forEach(([key, value]) => fixture.componentRef.setInput(key, value));
    fixture.detectChanges();
  }

  const icon = () => (fixture.nativeElement as HTMLElement).querySelector<SVGElement>('svg.blankslate-icon')!;

  it('renders a Primer Blankslate', () => {
    render();

    expect(fixture.nativeElement.querySelector('.blankslate-container > .blankslate')).toBeInTheDocument();
  });

  it('defaults the heading to the generic no data label', () => {
    render();

    expect(screen.getByRole('heading', { name: 'No data to display' })).toHaveClass('blankslate-heading');
  });

  it('renders the heading at level 3 by default', () => {
    render();

    expect(screen.getByRole('heading', { level: 3, name: 'No data to display' })).toBeInTheDocument();
  });

  it('renders the heading at the given level', () => {
    render({ headingLevel: 4 });

    expect(screen.getByRole('heading', { level: 4, name: 'No data to display' })).toHaveClass('blankslate-heading');
  });

  it('renders the given title as the heading', () => {
    render({ title: 'No work packages to display.' });

    expect(screen.getByRole('heading', { name: 'No work packages to display.' })).toBeInTheDocument();
    expect(screen.queryByText('No data to display')).not.toBeInTheDocument();
  });

  it('omits the description without a message', () => {
    render();

    expect(fixture.nativeElement.querySelector('p')).not.toBeInTheDocument();
  });

  it('renders the message as a plain text description', () => {
    render({ message: 'Either none have been created or all are <b>filtered</b> out.' });

    const description = screen.getByText('Either none have been created or all are <b>filtered</b> out.');
    expect(description).toHaveClass('blankslate-description');
    expect(description.querySelector('b')).not.toBeInTheDocument();
  });

  it('renders a decorative graph icon by default', () => {
    render();

    expect(icon()).toHaveClass('octicon', 'blankslate-icon');
    expect(icon()).toHaveAttribute('aria-hidden', 'true');
    expect(icon().querySelector('path')).toHaveAttribute('d', graphIconData['24'].paths[0]);
  });

  it('renders the given icon', () => {
    render({ icon: 'note' });

    expect(icon().querySelector('path')).toHaveAttribute('d', noteIconData['24'].paths[0]);
  });
});

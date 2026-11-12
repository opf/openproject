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

import '@openproject/primer-view-components/app/components/primer/alpha/tool_tip.js';
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { screen, waitFor } from '@testing-library/dom';
import { PrimerIconButtonComponent } from './icon-button.component';

describe('PrimerIconButtonComponent', () => {
  let component:PrimerIconButtonComponent;
  let fixture:ComponentFixture<PrimerIconButtonComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({imports: [PrimerIconButtonComponent]}).compileComponents();
  });

  beforeEach(() => {
    fixture = TestBed.createComponent(PrimerIconButtonComponent);
    component = fixture.componentInstance;
  });

  it('should create', () => {
    fixture.componentRef.setInput('icon', 'star');
    fixture.componentRef.setInput('label', 'Star');
    fixture.detectChanges();

    expect(component).toBeDefined();
  });

  it('renders', () => {
    fixture.componentRef.setInput('icon', 'star');
    fixture.componentRef.setInput('label', 'Star');
    fixture.detectChanges();

    const container:HTMLElement = fixture.nativeElement;
    const button = container.querySelector('.Button.Button--iconOnly');

    expect(button).not.toBeNull();
    expect(button?.querySelector('.Button-visual')).not.toBeNull();

    const tooltip = container.querySelector('tool-tip');

    expect(tooltip).not.toBeNull();
    expect(tooltip?.textContent).toEqual('Star');

    const tooltipId = tooltip!.id;

    expect(container.querySelector(`.Button.Button--iconOnly[aria-labelledby='${tooltipId}']`)).not.toBeNull();
  });

  it('renders description tooltip', () => {
    fixture.componentRef.setInput('icon', 'star');
    fixture.componentRef.setInput('label', 'Star');
    fixture.componentRef.setInput('description', 'Star this repository');
    fixture.detectChanges();

    const container:HTMLElement = fixture.nativeElement;

    const tooltip = container.querySelector('tool-tip');

    expect(tooltip).not.toBeNull();
    expect(tooltip?.textContent).toEqual('Star this repository');

    const tooltipId = tooltip!.id;

    expect(container.querySelector(`.Button.Button--iconOnly[aria-describedby='${tooltipId}']`)).not.toBeNull();
  });

  it('allows hiding tooltip', () => {
    fixture.componentRef.setInput('icon', 'star');
    fixture.componentRef.setInput('label', 'Star');
    fixture.componentRef.setInput('showTooltip', false);
    fixture.detectChanges();

    const container:HTMLElement = fixture.nativeElement;

    const tooltip = container.querySelector('tool-tip');

    expect(tooltip).toBeNull();
  });

  it('sets aria-label when tooltips are hidden', () => {
    fixture.componentRef.setInput('icon', 'star');
    fixture.componentRef.setInput('label', 'Star');
    fixture.componentRef.setInput('showTooltip', false);
    fixture.detectChanges();

    const container:HTMLElement = fixture.nativeElement;

    const button = container.querySelector('[aria-label=\'Star\']');

    expect(button).not.toBeNull();
  });

  it('keeps its label as name when a description is given', async () => {
    fixture.componentRef.setInput('icon', 'star');
    fixture.componentRef.setInput('label', 'Star');
    fixture.componentRef.setInput('description', 'Add to favorites');
    await fixture.whenStable();

    const button = screen.getByRole('button');

    expect(button).toHaveAccessibleName('Star');
    expect(button).toHaveAccessibleDescription('Add to favorites');
  });

  it('follows a buttonId change', async () => {
    fixture.componentRef.setInput('icon', 'star');
    fixture.componentRef.setInput('label', 'Star');
    fixture.componentRef.setInput('buttonId', 'first-id');
    await fixture.whenStable();

    fixture.componentRef.setInput('buttonId', 'second-id');
    await fixture.whenStable();

    await waitFor(() => {
      expect(screen.getByRole('button').id).toBe('second-id');
      expect(fixture.nativeElement.querySelector('tool-tip')).toHaveAttribute('for', 'second-id');
    });
  });
});

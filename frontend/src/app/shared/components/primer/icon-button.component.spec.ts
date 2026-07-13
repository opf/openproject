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
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

/* eslint-disable @typescript-eslint/no-unsafe-assignment */

import { ComponentFixture, TestBed } from '@angular/core/testing';
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
});

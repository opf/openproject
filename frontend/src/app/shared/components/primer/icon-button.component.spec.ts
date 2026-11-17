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
import { Component, signal } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { fireEvent, screen, waitFor } from '@testing-library/dom';
import { PrimerIconButtonComponent, PrimerIconButtonScheme } from './icon-button.component';

@Component({
  imports: [PrimerIconButtonComponent],
  template: `
    <button
      primerIconButton
      icon="star"
      class="consumer-class"
      [id]="id()"
      [label]="label()"
      [description]="description()"
      [showTooltip]="showTooltip()"
      [scheme]="scheme()"
      (click)="clicks.set(clicks() + 1)"
    ></button>
  `,
})
class HostComponent {
  readonly id = signal('star-button');
  readonly label = signal('Star');
  readonly description = signal<string|undefined>(undefined);
  readonly showTooltip = signal(true);
  readonly scheme = signal<PrimerIconButtonScheme>('default');
  readonly clicks = signal(0);
}

describe('PrimerIconButtonComponent', () => {
  const mount = async (configure:(host:HostComponent) => void = () => undefined) => {
    const fixture = TestBed.createComponent(HostComponent);
    configure(fixture.componentInstance);
    await fixture.whenStable();
    return fixture;
  };

  it('renders the icon inside the host button without a wrapper', async () => {
    const fixture = await mount();
    const button = screen.getByRole('button');

    expect(button.parentElement).toBe(fixture.nativeElement);
    expect(button).toHaveClass('Button', 'Button--iconOnly', 'Button--medium', 'Button--secondary', 'consumer-class');
    expect(button).toHaveAttribute('type', 'button');
    expect(button.querySelector('svg.Button-visual')).not.toBeNull();
  });

  it('applies the scheme', async () => {
    await mount((host) => host.scheme.set('invisible'));

    expect(screen.getByRole('button')).toHaveClass('Button--invisible');
    expect(screen.getByRole('button')).not.toHaveClass('Button--secondary');
  });

  it('names the button by its label tooltip', async () => {
    const fixture = await mount();
    const tooltip = (fixture.nativeElement as HTMLElement).querySelector('tool-tip')!;

    expect(tooltip).toHaveTextContent('Star');
    expect(tooltip).toHaveAttribute('for', 'star-button');
    await waitFor(() => expect(screen.getByRole('button')).toHaveAccessibleName('Star'));
  });

  it('keeps its label as name when a description is given', async () => {
    await mount((host) => host.description.set('Add to favorites'));

    await waitFor(() => {
      expect(screen.getByRole('button')).toHaveAccessibleName('Star');
      expect(screen.getByRole('button')).toHaveAccessibleDescription('Add to favorites');
    });
  });

  it('uses aria-label when the tooltip is hidden', async () => {
    const fixture = await mount((host) => host.showTooltip.set(false));

    expect((fixture.nativeElement as HTMLElement).querySelector('tool-tip')).toBeNull();
    expect(screen.getByRole('button')).toHaveAccessibleName('Star');
  });

  it('follows an id change', async () => {
    const fixture = await mount();

    fixture.componentInstance.id.set('second-id');
    await fixture.whenStable();

    await waitFor(() => expect((fixture.nativeElement as HTMLElement).querySelector('tool-tip')).toHaveAttribute('for', 'second-id'));
  });

  it('handles native clicks', async () => {
    const fixture = await mount();

    fireEvent.click(screen.getByRole('button'));

    expect(fixture.componentInstance.clicks()).toBe(1);
  });
});

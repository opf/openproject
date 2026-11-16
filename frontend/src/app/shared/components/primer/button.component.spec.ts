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

import { Component, signal } from '@angular/core';
import { SVGSize } from '@openproject/octicons-angular';
import { TestBed } from '@angular/core/testing';
import { fireEvent, screen } from '@testing-library/dom';
import { PrimerButtonComponent, PrimerButtonScheme } from './button.component';
import { DynamicIconName } from './dynamic-icon-map';

@Component({
  imports: [PrimerButtonComponent],
  template: `
    <button
      primerButton
      class="consumer-class"
      [scheme]="scheme()"
      [leadingIcon]="leadingIcon()"
      [trailingAction]="trailingAction()"
      [iconSize]="iconSize()"
      (click)="clicks.set(clicks() + 1)"
    >Star it</button>
  `,
})
class HostComponent {
  readonly scheme = signal<PrimerButtonScheme>('default');
  readonly leadingIcon = signal<DynamicIconName|undefined>(undefined);
  readonly trailingAction = signal<DynamicIconName|undefined>(undefined);
  readonly iconSize = signal<SVGSize>('small');
  readonly clicks = signal(0);
}

describe('PrimerButtonComponent', () => {
  const mount = async (configure:(host:HostComponent) => void = () => undefined) => {
    const fixture = TestBed.createComponent(HostComponent);
    configure(fixture.componentInstance);
    await fixture.whenStable();
    return fixture;
  };

  it('renders the label inside the host button without a wrapper', async () => {
    const fixture = await mount();
    const button = screen.getByRole('button', { name: 'Star it' });

    expect(button.parentElement).toBe(fixture.nativeElement);
    expect(button).toHaveClass('Button', 'Button--medium', 'Button--secondary', 'consumer-class');
    expect(button).not.toHaveClass('Button--iconOnly');
    expect(button).toHaveAttribute('type', 'button');
    expect(button.querySelector('.Button-content > .Button-label')).toHaveTextContent('Star it');
  });

  it('applies the link scheme', async () => {
    await mount((host) => host.scheme.set('link'));

    expect(screen.getByRole('button')).toHaveClass('Button--link');
    expect(screen.getByRole('button')).not.toHaveClass('Button--secondary');
  });

  it('renders no leading visual without an icon', async () => {
    await mount();

    expect(screen.getByRole('button').querySelector('.Button-leadingVisual')).toBeNull();
  });

  it('renders the leading icon as a decorative visual', async () => {
    await mount((host) => host.leadingIcon.set('star'));

    const visual = screen.getByRole('button').querySelector('.Button-leadingVisual svg');

    expect(visual).not.toBeNull();
    expect(visual).toHaveAttribute('aria-hidden', 'true');
    expect(screen.getByRole('button')).toHaveAccessibleName('Star it');
  });

  it('renders no trailing action without an icon', async () => {
    await mount();

    expect(screen.getByRole('button').querySelector('.Button-trailingAction')).toBeNull();
  });

  it('renders the trailing action as a decorative visual after the content', async () => {
    await mount((host) => host.trailingAction.set('triangle-down'));

    const visual = screen.getByRole('button').querySelector(':scope > .Button-content + .Button-trailingAction svg');

    expect(visual).not.toBeNull();
    expect(visual).toHaveAttribute('aria-hidden', 'true');
    expect(screen.getByRole('button')).toHaveAccessibleName('Star it');
  });

  it('renders its icons at the given size', async () => {
    await mount((host) => {
      host.leadingIcon.set('star');
      host.trailingAction.set('triangle-down');
      host.iconSize.set('xsmall');
    });

    const icons = screen.getByRole('button').querySelectorAll<SVGElement>('.Button-visual svg');

    expect(icons).toHaveLength(2);
    icons.forEach((icon) => expect(icon.getBoundingClientRect().height).toBe(12));
  });

  it('handles native clicks', async () => {
    const fixture = await mount();

    fireEvent.click(screen.getByRole('button'));

    expect(fixture.componentInstance.clicks()).toBe(1);
  });
});

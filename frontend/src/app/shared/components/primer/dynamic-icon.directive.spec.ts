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

/* eslint-disable @typescript-eslint/no-unsafe-assignment, @typescript-eslint/no-explicit-any */

import { ChangeDetectionStrategy, Component } from '@angular/core';
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { DynamicIconDirective } from './dynamic-icon.directive';

@Component({
  template: '<svg octicon [icon]="iconName" [size]="iconSize"></svg>',
  imports: [DynamicIconDirective],
  changeDetection: ChangeDetectionStrategy.OnPush
})
class TestHostComponent {
  iconName = '';
  iconSize:'small'|'medium'|'large' = 'medium';
}

describe('DynamicIconDirective', () => {
  let component:TestHostComponent;
  let fixture:ComponentFixture<TestHostComponent>;
  let svgElement:SVGElement;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [TestHostComponent],
    }).compileComponents();

    fixture = TestBed.createComponent(TestHostComponent);
    component = fixture.componentInstance;
    svgElement = fixture.nativeElement.querySelector('svg');
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  it('should create', () => {
    component.iconName = 'star';
    fixture.detectChanges();

    expect(component).toBeDefined();
    expect(svgElement).toBeDefined();
  });

  it('should render a valid star icon', () => {
    component.iconName = 'star';
    fixture.detectChanges();

    // Check that SVG attributes are set correctly
    expect(svgElement.getAttribute('viewBox')).toBeTruthy();
    expect(svgElement.getAttribute('fill')).toBe('currentColor');
    expect(svgElement.style.height).toBeTruthy();
    expect(svgElement.style.width).toBeTruthy();

    // Check that path elements are created
    const paths = svgElement.querySelectorAll('path');

    expect(paths.length).toBeGreaterThan(0);

    // Check that each path has a 'd' attribute
    paths.forEach(path => {
      expect(path.getAttribute('d')).toBeTruthy();
    });
  });

  it('should render a valid x icon', () => {
    component.iconName = 'x';
    fixture.detectChanges();

    // Check that SVG attributes are set correctly
    expect(svgElement.getAttribute('viewBox')).toBeTruthy();
    expect(svgElement.getAttribute('fill')).toBe('currentColor');
    expect(svgElement.style.height).toBeTruthy();
    expect(svgElement.style.width).toBeTruthy();

    // Check that path elements are created
    const paths = svgElement.querySelectorAll('path');

    expect(paths.length).toBeGreaterThan(0);
  });

  describe('icon sizes', () => {
    it('should render small icons with correct dimensions', () => {
      component.iconName = 'star';
      component.iconSize = 'small';
      fixture.detectChanges();

      expect(svgElement.style.height).toBe('16px');
    });

    it('should render large icons with correct dimensions', () => {
      // Create a fresh fixture for the large size test
      const largeFixture = TestBed.createComponent(TestHostComponent);
      const largeComponent = largeFixture.componentInstance;
      const largeSvgElement = largeFixture.nativeElement.querySelector('svg');

      largeComponent.iconName = 'star';
      largeComponent.iconSize = 'large';
      largeFixture.detectChanges();

      expect(largeSvgElement.style.height).toBe('64px');
    });

    it('should render medium icons by default', () => {
      component.iconName = 'star';
      // iconSize defaults to 'medium'
      fixture.detectChanges();

      expect(svgElement.style.height).toBe('32px');
    });
  });

  it('should clear existing content when rendering new icon', () => {
    component.iconName = 'star';
    fixture.detectChanges();

    const initialPaths = svgElement.querySelectorAll('path');

    expect(initialPaths.length).toBeGreaterThan(0);

    component.iconName = 'x';
    fixture.detectChanges();

    // Should have cleared and re-rendered
    const newPaths = svgElement.querySelectorAll('path');

    expect(newPaths.length).toBeGreaterThan(0);
  });

  it('should warn when rendering unknown icon', () => {
    vi.spyOn(console, 'warn');

    component.iconName = 'unknown-icon';
    fixture.detectChanges();

    expect(console.warn).toHaveBeenCalledWith('Unknown icon: unknown-icon');
  });

  it('should not render anything for unknown icon', () => {
    vi.spyOn(console, 'warn');

    component.iconName = 'unknown-icon';
    fixture.detectChanges();

    // Should not have set viewBox or other attributes
    expect(svgElement.getAttribute('viewBox')).toBeNull();
    expect(svgElement.getAttribute('fill')).toBeNull();

    // Should not have any paths
    const paths = svgElement.querySelectorAll('path');

    expect(paths.length).toBe(0);
  });

  it('should handle empty icon name', () => {
    vi.spyOn(console, 'warn');

    component.iconName = '';
    fixture.detectChanges();

    // Should not warn or render anything
    expect(console.warn).not.toHaveBeenCalled();
    expect(svgElement.getAttribute('viewBox')).toBeNull();

    const paths = svgElement.querySelectorAll('path');

    expect(paths.length).toBe(0);
  });

  it('should only render once when loaded', () => {
    vi.spyOn(console, 'warn');
    const directive = fixture.debugElement.children[0].injector.get(DynamicIconDirective);
    vi.spyOn(directive as any, 'renderIcon');

    component.iconName = 'star';
    fixture.detectChanges();

    // Change icon name after initial load - should not re-render
    component.iconName = 'x';
    fixture.detectChanges();

    expect((directive as any).renderIcon).toHaveBeenCalledTimes(1);
    expect((directive as any).renderIcon).toHaveBeenCalledWith('star');
  });
});

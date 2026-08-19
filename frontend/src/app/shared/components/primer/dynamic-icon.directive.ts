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

/* eslint-disable @angular-eslint/directive-selector */

import { Directive, effect, ElementRef, inject, input, Renderer2 } from '@angular/core';
import { closestNaturalHeight, sizeMap, SVGData, SVGSize } from '@openproject/octicons-angular';
import { ICON_MAP } from './dynamic-icon-map';

@Directive({ selector: 'svg[octicon]' })
export class DynamicIconDirective {
  private el = inject<ElementRef<SVGElement>>(ElementRef);
  private renderer = inject(Renderer2);

  readonly icon = input.required<string>();
  readonly size = input<SVGSize>('medium');

  constructor() {
    effect(() => {
      const name = this.icon();
      if (!name) return;

      this.renderIcon(name);
    });
  }

  private renderIcon(name:string) {
    const data = ICON_MAP[name];

    if (!data) {
      console.warn(`Unknown icon: ${name}`);
      return;
    }

    renderIconData(
      this.el.nativeElement,
      data,
      this.size(),
      this.renderer
    );
  }
}

function renderIconData(
  svg:SVGElement,
  iconData:SVGData,
  size:SVGSize = 'medium',
  renderer:Renderer2,
) {
  const height = sizeMap[size];
  const naturalHeight = closestNaturalHeight(Object.keys(iconData), height);
  const { width, paths } = iconData[naturalHeight.toString()];
  const elWidth =  height * (width / naturalHeight);

  renderer.setAttribute(svg, 'viewBox', `0 0 ${width} ${naturalHeight}`);
  renderer.setAttribute(svg, 'fill', 'currentColor');
  renderer.setStyle(svg, 'height', `${height}px`);
  renderer.setStyle(svg, 'width', `${elWidth}px`);

  svg.innerHTML = '';

  for (const d of paths) {
    const path = renderer.createElement('path', 'svg') as SVGPathElement;
    renderer.setAttribute(path, 'd', d);
    renderer.appendChild(svg, path);
  }
}

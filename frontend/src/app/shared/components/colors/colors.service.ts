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

import { Injectable } from '@angular/core';

export const colorModes = {
  lightHighContrast: 'lightHighContrast',
  light: 'light',
  dark: 'dark',
};

@Injectable({ providedIn: 'root' })
export class ColorsService {
  public toHsl(value:string):string {
    return `hsl(${this.valueHash(value)}, 50%, 30%)`;
  }

  public toHsla(value:string, opacity:number) {
    return `hsla(${this.valueHash(value)}, 50%, 30%, ${opacity}%)`;
  }

  protected valueHash(value:string) {
    let hash = 0;
    for (let i = 0; i < value.length; i++) {
      hash = value.charCodeAt(i) + ((hash << 5) - hash);
    }

    return hash % 360;
  }

  public colorMode():string {
    if (document.body.getAttribute('data-color-mode') === 'dark') {
      return colorModes.dark;
    }

    if (document.body.getAttribute('data-light-theme') === 'light_high_contrast') {
      return colorModes.lightHighContrast;
    }

    return colorModes.light;
  }
}

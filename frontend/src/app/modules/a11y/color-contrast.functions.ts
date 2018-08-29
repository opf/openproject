//-- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2017 Jean-Philippe Lang
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
// See doc/COPYRIGHT.rdoc for more details.
//++

export namespace ColorContrast {

  /**
   * Compute the best color for contrasting the given color.
   * Based on http://24ways.org/2010/calculating-color-contrast
   * 
   * Remember there is a background counterpart for this function
   * in color.rb
   * 
   * (#333/white)
   * @param hexcolor The normalized hex color
   */
  export function getContrastingColor(hexcolor?:string):string|null {
    if (hexcolor == null) {
      return null;
    }
    if (tooBrightForWhite(hexcolor)) {
      return '#333333';
    } else {
      return '#FFFFFF';
    }
  }

  export function getColorPatch(hexcolor:string, bright:string = '#FFFFFF', dark = '#333333'):{ bg:string, fg:string } {
    if (tooBrightForWhite(hexcolor)) {
      return { fg: dark, bg: hexcolor };
    } else {
      return { bg: bright, fg: hexcolor };
    }
  }

  export function tooBrightForWhite(hexcolor:string|null|undefined):boolean {
    if (hexcolor == null) {
      return false;
    }

    var r = parseInt(hexcolor.substr(1, 2), 16);
    var g = parseInt(hexcolor.substr(3, 2), 16);
    var b = parseInt(hexcolor.substr(5, 2), 16);

    var yiq = ((r * 299) + (g * 587) + (b * 114)) / 1000;

    return (yiq >= 128);
  }
}

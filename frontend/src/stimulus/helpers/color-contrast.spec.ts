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

import { composite, computedColor, contrastRatio, formatContrastRatio, normalizeHex, toHex } from './color-contrast';

describe('color contrast', () => {
  it('normalizes the same short and long hex inputs as the color model', () => {
    expect(normalizeHex(' abc ')).toBe('#AABBCC');
    expect(normalizeHex('#aabbcc')).toBe('#AABBCC');
    expect(normalizeHex('123456')).toBe('#123456');
    expect(normalizeHex('#abcd')).toBeNull();
    expect(normalizeHex('')).toBeNull();
  });

  it('evaluates WCAG luminance rather than perceived brightness', () => {
    expect(contrastRatio([0, 0, 0, 1], [255, 255, 255, 1])).toBe(21);
    expect(contrastRatio([255, 255, 255, 1], [255, 255, 255, 1])).toBe(1);
    expect(contrastRatio([119, 119, 119, 1], [255, 255, 255, 1])).toBeLessThan(4.5);
    expect(contrastRatio([118, 118, 118, 1], [255, 255, 255, 1])).toBeGreaterThan(4.5);
  });

  it('keeps rounded failing ratios distinguishable from the passing threshold', () => {
    expect(formatContrastRatio(4.499)).toBe('<4.50:1');
    expect(formatContrastRatio(4.49)).toBe('4.49:1');
    expect(formatContrastRatio(4.5)).toBe('4.50:1');
    expect(formatContrastRatio(4.501)).toBe('4.50:1');
  });

  it('reads opaque RGB and fractional relative CSS colors without treating blue as alpha', () => {
    expect(computedColor('rgb(255, 105, 180)')).toEqual([255, 105, 180, 1]);
    expect(computedColor('rgba(255, 105, 180, 0.18)')).toEqual([255, 105, 180, 0.18]);
    expect(computedColor('color(srgb 1 0.5 0 / 0.18)')).toEqual([255, 127.5, 0, 0.18]);
  });

  it('composites highlighting over the actual theme surface', () => {
    expect(toHex(composite([255, 0, 0, 0.18], [255, 255, 255, 1]))).toBe('#FFD1D1');
    expect(toHex(composite([255, 0, 0, 0.18], [0, 0, 0, 1]))).toBe('#2E0000');
    expect(composite([255, 0, 0, 0], [13, 17, 23, 1])).toEqual([13, 17, 23, 1]);
  });
});

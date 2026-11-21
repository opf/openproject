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

import { afterEach, beforeEach, describe, expect, it, MockInstance, vi } from 'vitest';
import { platformBadgesMultiUrlDrags } from './platform';
import { usePlatform } from './testing/platform';

describe('platformBadgesMultiUrlDrags', () => {
  const pretendPlatform = usePlatform('macOS');

  it('is true for Chromium 152 on macOS', () => {
    pretendPlatform('macOS', [{ brand: 'Chromium', version: '152' }, { brand: 'Google Chrome', version: '152' }]);

    expect(platformBadgesMultiUrlDrags()).toBe(true);
  });

  it('is true for later Chromium-based browsers on macOS', () => {
    pretendPlatform('macOS', [{ brand: 'Chromium', version: '160' }, { brand: 'Microsoft Edge', version: '160' }]);

    expect(platformBadgesMultiUrlDrags()).toBe(true);
  });

  it('is false before Chromium 152', () => {
    pretendPlatform('macOS', [{ brand: 'Chromium', version: '151' }]);

    expect(platformBadgesMultiUrlDrags()).toBe(false);
  });

  it('is false for Chromium on other platforms', () => {
    pretendPlatform('Windows', [{ brand: 'Chromium', version: '152' }]);

    expect(platformBadgesMultiUrlDrags()).toBe(false);
  });

  it('is false without a Chromium brand', () => {
    pretendPlatform('macOS', [{ brand: 'Not.A/Brand', version: '99' }]);

    expect(platformBadgesMultiUrlDrags()).toBe(false);
  });

  describe('without client hints', () => {
    const macChrome = (version:number) => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 '
      + `(KHTML, like Gecko) Chrome/${version}.0.0.0 Safari/537.36`;
    let userAgentSpy:MockInstance<() => string>;

    beforeEach(() => {
      Object.defineProperty(navigator, 'userAgentData', { configurable: true, value: undefined });
      userAgentSpy = vi.spyOn(navigator, 'userAgent', 'get');
    });

    afterEach(() => {
      userAgentSpy.mockRestore();
    });

    it('is true for Chrome 152 on macOS', () => {
      userAgentSpy.mockReturnValue(macChrome(152));

      expect(platformBadgesMultiUrlDrags()).toBe(true);
    });

    it('is true for Edge 152 on macOS', () => {
      userAgentSpy.mockReturnValue(`${macChrome(152)} Edg/152.0.0.0`);

      expect(platformBadgesMultiUrlDrags()).toBe(true);
    });

    it('is false for Chrome 151 on macOS', () => {
      userAgentSpy.mockReturnValue(macChrome(151));

      expect(platformBadgesMultiUrlDrags()).toBe(false);
    });

    it('is false for Chrome 152 on Windows', () => {
      userAgentSpy.mockReturnValue('Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
        + '(KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36');

      expect(platformBadgesMultiUrlDrags()).toBe(false);
    });

    it('is false for Safari on macOS', () => {
      userAgentSpy.mockReturnValue('Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 '
        + '(KHTML, like Gecko) Version/26.0 Safari/605.1.15');

      expect(platformBadgesMultiUrlDrags()).toBe(false);
    });

    it('is false for Firefox on macOS', () => {
      userAgentSpy.mockReturnValue('Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:152.0) Gecko/20100101 Firefox/152.0');

      expect(platformBadgesMultiUrlDrags()).toBe(false);
    });

    it('is false for Chrome on an iPad requesting the desktop site', () => {
      userAgentSpy.mockReturnValue('Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 '
        + '(KHTML, like Gecko) CriOS/152.0.0.0 Version/26.0 Safari/605.1.15');

      expect(platformBadgesMultiUrlDrags()).toBe(false);
    });
  });
});

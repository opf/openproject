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

import { afterEach, beforeEach, MockInstance, vi } from 'vitest';

export function usePlatform(defaultPlatform = 'Linux'):(platform:string) => void {
  let descriptor:PropertyDescriptor|undefined;
  let platformSpy:MockInstance<() => string>;

  const pretendPlatform = (platform:string) => {
    platformSpy.mockReturnValue(platform);
    Object.defineProperty(navigator, 'userAgentData', { configurable: true, value: { platform } });
  };

  beforeEach(() => {
    descriptor = Object.getOwnPropertyDescriptor(navigator, 'userAgentData');
    platformSpy = vi.spyOn(navigator, 'platform', 'get');
    pretendPlatform(defaultPlatform);
  });

  afterEach(() => {
    platformSpy.mockRestore();
    if (descriptor) {
      Object.defineProperty(navigator, 'userAgentData', descriptor);
    } else {
      delete (navigator as Navigator & { userAgentData?:unknown }).userAgentData;
    }
  });

  return pretendPlatform;
}

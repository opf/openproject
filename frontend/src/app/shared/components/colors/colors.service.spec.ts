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

import { ColorsService } from 'core-app/shared/components/colors/colors.service';
// Shared with modules/avatars/spec/lib/open_project/avatars/initials_svg_spec.rb so both
// implementations are checked against the exact same inputs/outputs and can't drift apart
// unnoticed again.
import fixtures from '../../../../../../modules/avatars/spec/fixtures/avatar_hue_parity.json';

describe('ColorsService', () => {
  let service:ColorsService;

  beforeEach(() => {
    service = new ColorsService();
  });

  describe('toHsl', () => {
    it('matches the backend hue_for for every shared fixture', () => {
      fixtures.forEach((fixture) => {
        const match = /^hsl\((-?\d+), 50%, 30%\)$/.exec(service.toHsl(fixture.value));
        const hue = Number(match?.[1]);

        // hsl() hue is cyclic: JS's `%` keeps the dividend's sign (e.g. -69) while Ruby's
        // always returns a positive remainder (e.g. 291) for the same underlying hash. Both
        // render the identical color, so compare the normalized hue rather than the raw string.
        expect((hue + 360) % 360).toBe(fixture.expectedHue);
      });
    });
  });
});

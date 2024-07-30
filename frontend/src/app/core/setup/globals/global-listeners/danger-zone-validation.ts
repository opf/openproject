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

// Moved from app/assets/javascript/danger_zone_validation.js
// Make the whole danger zone a component the next time this needs changes!

export function dangerZoneValidation() {
  // This will only work iff there is a single danger zone on the page
  const dangerZoneVerification = jQuery('.danger-zone--verification');
  const expectedValue = jQuery('.danger-zone--expected-value');

  // When no expected value is set up, do not disable button
  if (!expectedValue[0]) {
    return;
  }

  const expectedText = expectedValue.text();
  dangerZoneVerification.find('input').on('input', () => {
    const actualValue = dangerZoneVerification.find('input').val() as string;
    if (expectedText.toLowerCase() === actualValue.toLowerCase()) {
      dangerZoneVerification.find('button').prop('disabled', false);
    } else {
      dangerZoneVerification.find('button').prop('disabled', true);
    }
  });
}

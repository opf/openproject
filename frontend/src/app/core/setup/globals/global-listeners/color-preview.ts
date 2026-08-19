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

/**
 * Moved from app/assets/javascripts/colors.js
 *
 * Make this a component instead of modifying it the next time
 * this needs changes
 */
export function makeColorPreviews() {
  document.querySelectorAll<HTMLElement>('.color--preview').forEach(function (preview) {
    let input:HTMLInputElement|null = null;
    const target = preview.dataset.target;

    if (target) {
      input = document.querySelector<HTMLInputElement>(target);
    } else {
      const next = preview.nextElementSibling;
      if (next && next instanceof HTMLInputElement) {
        input = next;
      }
    }

    if (input === null) {
      return;
    }

    const listener = function () {
      let previewColor = '';

      if (input.value && input.value.length > 0) {
        previewColor = input.value;
      } else if (input.getAttribute('placeholder')
        && input.getAttribute('placeholder')!.length > 0) {
        previewColor = input.getAttribute('placeholder')!;
      }

      preview.style.backgroundColor = previewColor;
    };

    input.addEventListener('keyup', listener);
    input.addEventListener('change', listener);
    input.addEventListener('focus', listener);
    listener();
  });
}

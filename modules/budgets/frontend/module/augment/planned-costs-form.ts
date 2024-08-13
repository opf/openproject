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

export class PlannedCostsFormAugment {
  static listen():void {
    jQuery(document).on('click', '.costs--edit-planned-costs-btn', (evt) => {
      const link = evt.target as HTMLElement;
      const form = link.nextElementSibling as HTMLElement;

      link.hidden = true;
      form.hidden = false;

      const input = form.querySelector('input') as HTMLInputElement;
      input.disabled = false;
    });

    jQuery(document).on('click', '.costs--edit-planned-costs-cancel-btn', (evt) => {
      const form = (evt.target as HTMLElement).closest('.costs--edit-form') as HTMLElement;
      const link = form.previousElementSibling as HTMLElement;

      link.hidden = false;
      form.hidden = true;

      const input = form.querySelector('input') as HTMLInputElement;
      input.disabled = true;
    });
  }
}

//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2021 the OpenProject GmbH
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
// See docs/COPYRIGHT.rdoc for more details.
//++

import { Injectable } from "@angular/core";

@Injectable()
export class CostSubformAugmentService {

  constructor() {
    jQuery('costs-subform').each((i, match) => {
      const el = jQuery(match);

      const container = el.find('.subform-container');

      const templateEl = el.find('.subform-row-template');
      templateEl.detach();
      const template = templateEl[0].outerHTML;
      let rowIndex = parseInt(el.attr('item-count')!);

      el.on('click', '.delete-row-button,.delete-budget-item', (evt:any) => {
        jQuery(evt.target).closest('.subform-row').remove();
        return false;
      });

      // Add new row handler
      el.find('.add-row-button,.wp-inline-create--add-link').click((evt:any) => {
        evt.preventDefault();
        const row = jQuery(template.replace(/INDEX/g, rowIndex.toString()));
        row.show();
        row.removeClass('subform-row-template');
        row.find('input.costs-date-picker').prop('required', true);
        row.find('input[id^="cost_type_new_rate_attributes"]').prop('required', true);

        container.append(row);
        rowIndex += 1;

        container.find('.subform-row:last-child input:first').focus();

        return false;
      });
    });
  }
}



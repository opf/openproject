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

export class PlannedCostsFormAugment {

  public obj:JQuery;
  public objId:string;
  public objName:string;
  public placeholder:string;

  static listen() {
    jQuery(document).on('click', '.costs--edit-planned-costs-btn', (evt) => {
      const form = jQuery(evt.target as any).closest('cost-unit-subform') as JQuery;
      new PlannedCostsFormAugment(form);
    });
  }

  constructor(public $element:JQuery) {
    this.objId = this.$element.attr('obj-id')!;
    this.objName = this.$element.attr('obj-name')!;
    this.obj = jQuery(`#${this.objId}_costs`) as any;
    this.placeholder = this.$element.data('placeholder');

    this.makeEditable();
  }

  public makeEditable() {
    this.edit_and_focus();
  }

  private edit_and_focus() {
    this.edit();

    jQuery('#' + this.objId + '_costs_edit').trigger('focus');
    jQuery('#' + this.objId + '_costs_edit').trigger('select');
  }

  private getCurrency() {
    return jQuery('#' + this.objId + '_currency').val();
  }

  private getValue() {
    return jQuery('#' + this.objId + '_cost_value').val();
  }

  private edit() {
    this.obj.hide();

    const id = this.obj[0].id;
    const currency = this.getCurrency();
    const value = this.getValue();
    const name = this.objName;
    const placeholder = this.placeholder;

    const template = `
      <section class="form--section" id="${id}_section">
        <div class="form--field">
          <div class="form--field-container">
            <div id="${id}_cancel" class="form--field-affix -transparent icon icon-close"></div>
            <div id="${id}_editor" class="form--text-field-container">
                <input id="${id}_edit"
                       class="form--text-field"
                       name="${name}"
                       value="${value}"
                       placeholder="${placeholder}"
                       class="currency"
                       type="text" />
            </div>
            <div class="form--field-affix" id="${id}_affix">${currency}</div>
          </div>
        </div>
      </section>
    `;

    jQuery(template).insertAfter(this.obj);

    const that = this;
    jQuery('#' + id + '_cancel').on('click', function () {
      jQuery('#' + id + '_section').remove();
      that.obj.show();
      return false;
    });
  }
}


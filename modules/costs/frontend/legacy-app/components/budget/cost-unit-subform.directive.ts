// -- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
// See doc/COPYRIGHT.rdoc for more details.
// ++

export class CostUnitSubformController {

  public objId:string;
  public objName:string;

  constructor(public $element:ng.IAugmentedJQuery) {
    this.objId = this.$element.attr('obj-id')!;
    this.objName = this.$element.attr('obj-name')!;

    // Add new row handler
    $element.find('#' + this.objId).click(() => {
      this.makeEditable('#' + this.objId, this.objName);
    });
  }

  private getCurrencyValue(str:string) {
    var result = str.match(/^\s*(([0-9]+[.,])+[0-9]+) (.+)\s*/);
    return result ? new Array(result[1], result[3]) : new Array(str, "");
  }

  public makeEditable(id:string, name:string) {
    var obj = jQuery(id);
    this.edit_and_focus(obj, name);
  }

  private edit_and_focus(obj:any, name:string) {
    this.edit(obj, name);

    jQuery('#' + obj[0].id + '_edit').focus();
    jQuery('#' + obj[0].id + '_edit').select();
  }

  private edit(obj:any, name:string, obj_value?:any) {
    obj.hide();

    var obj_value = typeof (obj_value) != 'undefined' ? obj_value : obj[0].innerHTML;
    var parsed = this.getCurrencyValue(obj_value);
    var value = parsed[0];
    var currency = parsed[1];

    var form_start = '<section class="form--section" id="' + obj[0].id +
      '_section"><div class="form--field"><div class="form--field-container">';
    var button = '<div id="' + obj[0].id +
      '_cancel" class="form--field-affix -transparent icon icon-close"></div>';
    var span = '<div id="' + obj[0].id + '_editor" class="form--text-field-container">';
    span += '<input id="' + obj[0].id + '_edit" class="form--text-field" name="' + name + '" value="' + value + '" class="currency" type="text" /> ';
    span += '</div>';

    var affix = '<div class="form--field-affix" id="' + obj[0].id + '_affix">' +
      currency +
      '</div>';
    var form_end = '</div></div></section>';

    jQuery(form_start + button + span + affix + form_end).insertAfter(obj);

    var that = this;
    jQuery('#' + obj[0].id + '_cancel').on('click', function() {
      that.cleanUp(obj)
      return false;
    });
  }

  private cleanUp(obj:any) {
    jQuery('#' + obj[0].id + '_section').remove();
    obj.show();
  }
}

function costUnitSubform():any {
  return {
    restrict: 'E',
    scope: {},
    bindToController: true,
    controller: CostUnitSubformController,
    controllerAs: '$ctrl'
  };
}

angular.module('OpenProjectLegacy').directive('costUnitSubform', costUnitSubform);

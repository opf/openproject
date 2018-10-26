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

import {openprojectLegacyModule} from "core-app/openproject-legacy-app";

export class WpCustomActionsAdminDateActionComponent {
  public valueVisible = false;
  public fieldName:string;
  public fieldValue:string;
  public visibleValue:string;
  public selectedOperator:any;
  private i18n:any;

  private onKey = 'on';
  private currentKey = 'current';
  private currentFieldValue = '%CURRENT_DATE%';

  public operators:{key:string, label:string}[];

  constructor() {
    window.OpenProject.getPluginContext().then((context) => {
      this.i18n = context.services.i18n;

      this.initialize();
    });
  }

  // cannot use $onInit as it would be called before the operators gets filled
  public initialize() {
    this.operators = [{key: this.onKey, label: this.i18n.t('js.custom_actions.date.specific')},
      {key: this.currentKey, label: this.i18n.t('js.custom_actions.date.current_date')}];

    if (this.fieldValue === this.currentFieldValue) {
      this.selectedOperator = this.operators[1];
    } else {
      this.selectedOperator = this.operators[0];
      this.visibleValue = this.fieldValue;
    }

    this.toggleValueVisibility();
  }

  public toggleValueVisibility() {
    this.valueVisible = this.selectedOperator.key === this.onKey;
    this.updateDbValue();
  }

  private updateDbValue() {
    if (this.selectedOperator.key === this.currentKey) {
      this.fieldValue = this.currentFieldValue;
    } else {
      this.fieldValue = this.visibleValue;
    }
  }

  public get fieldId() {
    // replace all square brackets by underscore
    // to match the label's for value
    return this.fieldName
               .replace(/\[|\]/g, '_')
               .replace('__', '_')
               .replace(/_$/, '');
  }
}

openprojectLegacyModule.component('wpCustomActionsAdminDateAction', {
  template: require('!!raw-loader!./date-action.component.html'),
  controller: WpCustomActionsAdminDateActionComponent,
  bindings: {
    fieldName: "@",
    fieldValue: "@",
  }
});


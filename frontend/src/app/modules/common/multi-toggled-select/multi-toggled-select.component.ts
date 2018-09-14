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

import {Component, EventEmitter, Input, OnInit, Output} from "@angular/core";
import {I18nService} from "core-app/modules/common/i18n/i18n.service";

export interface MultiToggledSelectOption {
  name:string;
  singleOnly:true|undefined;
  value:any;
}

@Component({
  selector: 'multi-toggled-select',
  templateUrl: './multi-toggled-select.component.html'
})
export class MultiToggledSelectComponent<T extends MultiToggledSelectOption> implements OnInit {
  @Input() availableOptions:T[];
  @Input() initialSelection:T|T[];
  @Input() selectHtmlId:string|undefined;
  @Input() isRequired:boolean = false;
  @Input() isDisabled:boolean = false;
  @Input() currentValueInvalid:boolean = false;

  @Output() onValueChange = new EventEmitter<T[]|T|undefined>();
  @Output() onMultiToggle = new EventEmitter<boolean>();
  @Output() onValueKeydown = new EventEmitter<KeyboardEvent>();

  public text = {
    requiredPlaceholder: this.I18n.t('js.placeholders.selection'),
    placeholder: this.I18n.t('js.placeholders.default'),
    switch_to_single_select: this.I18n.t('js.work_packages.label_switch_to_single_select'),
    switch_to_multi_select: this.I18n.t('js.work_packages.label_switch_to_multi_select'),
  };

  /** Whether we're currently multi-selecting */
  public isMultiselect = false;

  /** Current selected option */
  private _selectedOption:T|T[]|undefined;

  constructor(protected readonly I18n:I18nService) {
  }

  ngOnInit() {
    this.selectedOption = this.initialSelection;
    this.isMultiselect = this.isValueMulti();
  }

  public isValueMulti() {
    return (this.selectedOption instanceof Array) && this.selectedOption.length > 1;
  }

  public triggerChangeOnSingleSelect() {
    if (!this.isMultiselect) {
      this.onValueChange.emit(this.selectedOption);
    }
  }

  public emitValueChange() {
    this.onValueChange.emit(this.selectedOption);
  }

  public toggleMultiselect() {
    this.isMultiselect = !this.isMultiselect;

    if (this.isValueMulti()) {
      this._selectedOption = (this.selectedOption as T[])[0];
    } else {
      this._selectedOption = this.selectedOption;
    }
  }

  public get availableMultiOptions() {
    return this.availableOptions.filter(el => el.singleOnly !== true);
  }

  public get selectedOption():T|T[]|undefined {
    return this._selectedOption;
  }

  /**
   * Map the ValueOption to the actual HalResource option
   * @param val
   */
  public set selectedOption(val:T|T[]|undefined) {
    this._selectedOption = val;
  }

  public get nullOption():T {
    return { name: this.text.placeholder, value: '' } as T;
  }
}

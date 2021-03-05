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

import { ApplicationRef, ChangeDetectorRef, Component, ElementRef, OnInit } from '@angular/core';
import { I18nService } from 'core-app/modules/common/i18n/i18n.service';


export const customDateActionAdminSelector = 'custom-date-action-admin';

@Component({
  selector: customDateActionAdminSelector,
  templateUrl: './custom-date-action-admin.html'
})
export class CustomDateActionAdminComponent implements OnInit {
  public valueVisible = false;
  public fieldName:string;
  public fieldValue:string;
  public visibleValue:string;
  public selectedOperator:any;

  private onKey = 'on';
  private currentKey = 'current';
  private currentFieldValue = '%CURRENT_DATE%';

  public operators = [
    { key: this.onKey, label: this.I18n.t('js.custom_actions.date.specific') },
    { key: this.currentKey, label: this.I18n.t('js.custom_actions.date.current_date') }
  ];

  constructor(private elementRef:ElementRef,
              private cdRef:ChangeDetectorRef,
              public appRef:ApplicationRef,
              private I18n:I18nService) {
  }

  // cannot use $onInit as it would be called before the operators gets filled
  public ngOnInit() {
    const element = this.elementRef.nativeElement as HTMLElement;
    this.fieldName = element.dataset.fieldName!;
    this.fieldValue = element.dataset.fieldValue!;

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
    if (this.fieldValue === this.currentFieldValue) {
      this.fieldValue = '';
    }

    this.updateDbValue();
  }

  private updateDbValue() {
    if (this.selectedOperator.key === this.currentKey) {
      this.fieldValue = this.currentFieldValue;
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

  updateField(val:string) {
    this.fieldValue = val;
    this.cdRef.detectChanges();
  }
}



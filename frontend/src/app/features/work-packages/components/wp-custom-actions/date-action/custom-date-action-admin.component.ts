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

import {
  ApplicationRef,
  ChangeDetectionStrategy,
  ChangeDetectorRef,
  Component,
  ElementRef,
  inject,
  OnInit,
} from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';

@Component({
  selector: 'opce-custom-date-action-admin',
  templateUrl: './custom-date-action-admin.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
  standalone: false,
})
export class CustomDateActionAdminComponent implements OnInit {
  public valueVisible = false;

  public fieldName = '';

  public fieldValue = '';

  public visibleValue = '';

  private onKey = 'on';

  private currentKey = 'current';

  private currentFieldValue = '%CURRENT_DATE%';

  private elementRef = inject<ElementRef<HTMLElement>>(ElementRef);
  private cdRef = inject(ChangeDetectorRef);
  public appRef = inject(ApplicationRef);
  private I18n = inject(I18nService);

  public selectedOperatorKey = this.onKey;

  public operators = [
    { key: this.onKey, label: this.I18n.t('js.custom_actions.date.specific') },
    { key: this.currentKey, label: this.I18n.t('js.custom_actions.date.current_date') },
  ];

  // cannot use $onInit as it would be called before the operators gets filled
  public ngOnInit() {
    const element = this.elementRef.nativeElement;
    this.fieldName = element.dataset.fieldName! || '';
    this.fieldValue = element.dataset.fieldValue! || '';

    if (this.fieldValue === this.currentFieldValue) {
      this.selectedOperatorKey = this.currentKey;
    } else {
      this.selectedOperatorKey = this.onKey;
      this.visibleValue = this.fieldValue;
    }

    this.toggleValueVisibility();
    this.cdRef.markForCheck();
  }

  public toggleValueVisibility() {
    this.valueVisible = this.selectedOperatorKey === this.onKey;
    if (this.fieldValue === this.currentFieldValue) {
      this.fieldValue = '';
    }

    this.updateDbValue();
    this.cdRef.detectChanges();
  }

  private updateDbValue() {
    if (this.selectedOperatorKey === this.currentKey) {
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

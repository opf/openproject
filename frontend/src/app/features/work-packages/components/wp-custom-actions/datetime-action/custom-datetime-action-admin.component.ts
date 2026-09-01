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

interface SelectOption {
  key:string;
  label:string;
}

const SECONDS_PER_MINUTE = 60;
const SECONDS_PER_HOUR = 3600;
const SECONDS_PER_DAY = 86400;

@Component({
  selector: 'opce-custom-datetime-action-admin',
  templateUrl: './custom-datetime-action-admin.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
  standalone: false,
})
export class CustomDateTimeActionAdminComponent implements OnInit {
  public fieldName = '';

  public fieldValue = '';

  private onKey = 'on';

  private currentKey = 'current';

  private relativeKey = 'relative';

  private agoKey = 'ago';

  private currentFieldValue = '%CURRENT_DATETIME%';

  private relativeFieldValue = '%RELATIVE_DATETIME%';

  private elementRef = inject<ElementRef<HTMLElement>>(ElementRef);
  private cdRef = inject(ChangeDetectorRef);
  public appRef = inject(ApplicationRef);
  private I18n = inject(I18nService);

  public selectedOperatorKey = this.onKey;

  public operators:SelectOption[] = [
    { key: this.onKey, label: this.I18n.t('js.custom_actions.datetime.fixed') },
    { key: this.currentKey, label: this.I18n.t('js.custom_actions.datetime.current') },
    { key: this.relativeKey, label: this.I18n.t('js.custom_actions.datetime.relative') },
  ];

  public relations:SelectOption[] = [
    { key: 'since', label: this.I18n.t('js.custom_actions.datetime.since') },
    { key: this.agoKey, label: this.I18n.t('js.custom_actions.datetime.ago') },
  ];

  public hours = this.countOptions(23, 1, 'hours');

  public minutes = this.countOptions(59, 5, 'minutes');

  public selectedRelationKey = 'since';

  public selectedDays = 0;

  public selectedHours = '0';

  public selectedMinutes = '0';

  public ngOnInit():void {
    const element = this.elementRef.nativeElement;
    this.fieldName = element.dataset.fieldName! || '';
    this.fieldValue = element.dataset.fieldValue! || '';

    if (this.fieldValue === this.currentFieldValue) {
      this.selectedOperatorKey = this.currentKey;
    } else if (this.fieldValue.startsWith(this.relativeFieldValue)) {
      this.selectedOperatorKey = this.relativeKey;
      this.decomposeRelativeValue();
    } else {
      this.selectedOperatorKey = this.onKey;
    }

    this.cdRef.markForCheck();
  }

  public get fixedValueActive():boolean {
    return this.selectedOperatorKey === this.onKey;
  }

  public get relativeValueActive():boolean {
    return this.selectedOperatorKey === this.relativeKey;
  }

  public onOperatorChange():void {
    if (this.selectedOperatorKey === this.currentKey) {
      this.fieldValue = this.currentFieldValue;
    } else if (this.relativeValueActive) {
      this.updateRelativeValue();
    } else {
      this.fieldValue = '';
    }

    this.cdRef.detectChanges();
  }

  public onRelativeChange():void {
    this.updateRelativeValue();
    this.cdRef.detectChanges();
  }

  public updateFixedValue(value:string):void {
    this.fieldValue = value;
    this.cdRef.detectChanges();
  }

  public get daysLabel():string {
    return this.I18n.t('js.custom_actions.datetime.days', { count: Number(this.selectedDays) || 0 });
  }

  public get fieldId():string {
    return this.fieldName
      .replace(/\[|\]/g, '_')
      .replace('__', '_')
      .replace(/_$/, '');
  }

  private updateRelativeValue():void {
    let seconds = (Number(this.selectedDays) || 0) * SECONDS_PER_DAY
      + parseInt(this.selectedHours, 10) * SECONDS_PER_HOUR
      + parseInt(this.selectedMinutes, 10) * SECONDS_PER_MINUTE;

    if (this.selectedRelationKey === this.agoKey) {
      seconds *= -1;
    }

    this.fieldValue = `${this.relativeFieldValue}${seconds}`;
  }

  private decomposeRelativeValue():void {
    let seconds = parseInt(this.fieldValue.replace(this.relativeFieldValue, ''), 10) || 0;

    if (seconds < 0) {
      this.selectedRelationKey = this.agoKey;
      seconds *= -1;
    }

    this.selectedDays = Math.floor(seconds / SECONDS_PER_DAY);
    seconds %= SECONDS_PER_DAY;

    this.selectedHours = String(Math.floor(seconds / SECONDS_PER_HOUR));
    seconds %= SECONDS_PER_HOUR;

    const minuteStep = 5;
    const minutes = Math.min(55, Math.round(seconds / SECONDS_PER_MINUTE / minuteStep) * minuteStep);
    this.selectedMinutes = String(minutes);
  }

  private countOptions(max:number, step:number, unit:string):SelectOption[] {
    const options:SelectOption[] = [];
    for (let i = 0; i <= max; i += step) {
      options.push({
        key: String(i),
        label: this.I18n.t(`js.custom_actions.datetime.${unit}`, { count: i }),
      });
    }
    return options;
  }
}

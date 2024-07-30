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

import { DisplayField } from 'core-app/shared/components/fields/display/display-field.module';
import { InjectField } from 'core-app/shared/helpers/angular/inject-field.decorator';
import { TimezoneService } from 'core-app/core/datetime/timezone.service';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { ExcludedIconHelperService } from 'core-app/shared/components/fields/display/field-types/excluded-icon-helper.service';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import {
  uiStateLinkClass,
} from 'core-app/features/work-packages/components/wp-fast-table/builders/ui-state-link-builder';
import {
  HierarchyQueryLinkHelperService,
} from 'core-app/shared/components/fields/display/field-types/hierarchy-query-link-helper.service';

export class WorkDisplayField extends DisplayField {
  @InjectField() timezoneService:TimezoneService;

  @InjectField() PathHelper:PathHelperService;

  @InjectField() apiV3Service:ApiV3Service;

  @InjectField() excludedIconHelperService:ExcludedIconHelperService;

  @InjectField() hierarchyQueryLinkHelper:HierarchyQueryLinkHelperService;

  private derivedText = this.I18n.t('js.label_value_derived_from_children');

  public get valueString():string {
    return this.timezoneService.formattedChronicDuration(this.value as string);
  }

  /**
   * Duration fields may have an additional derived value
   */
  public get derivedPropertyName():string {
    return `derived${this.name.charAt(0).toUpperCase()}${this.name.slice(1)}`;
  }

  public get derivedValue():string|null {
    // eslint-disable-next-line @typescript-eslint/no-unsafe-member-access
    return this.resource[this.derivedPropertyName] as string|null;
  }

  public get derivedValueString():string {
    const value = this.derivedValue;

    if (value) {
      return this.timezoneService.formattedChronicDuration(value);
    }
    return this.placeholder;
  }

  public render(element:HTMLElement, displayText:string):void {
    if (this.isEmpty()) {
      element.textContent = this.placeholder;
      return;
    }

    element.classList.add('split-time-field');
    this.renderActual(element, displayText);

    const derived = this.derivedValue;
    if (derived && this.hasChildren()) {
      this.renderSeparator(element);
      this.renderDerived(element, this.derivedValueString);
    }
  }

  public renderActual(element:HTMLElement, displayText:string):void {
    const span = document.createElement('span');

    if (this.value) {
      span.textContent = displayText;
      span.title = this.valueString;
    } else {
      span.textContent = this.texts.placeholder;
      span.title = this.texts.placeholder;
    }
    span.classList.add('-actual-value');

    if (this.value) {
      this.excludedIconHelperService.addIconIfExcludedFromTotals(span, this.resource as WorkPackageResource);
    }
    element.appendChild(span);
  }

  public renderSeparator(element:HTMLElement) {
    const span = document.createElement('span');
    span.classList.add('-separator');
    span.textContent = '·';
    span.ariaHidden = 'true';
    element.appendChild(span);
  }

  public renderDerived(element:HTMLElement, displayText:string):void {
    const link = document.createElement('a');

    link.textContent = `Σ ${displayText}`;
    link.title = `${this.derivedValueString} ${this.derivedText}`;
    link.classList.add('-derived-value', uiStateLinkClass);

    this.hierarchyQueryLinkHelper.addHref(link, this.resource);

    element.appendChild(link);
  }

  public get title():string|null {
    return null; // we want to render separate titles ourselves
  }

  public isEmpty():boolean {
    // eslint-disable-next-line @typescript-eslint/no-unsafe-assignment
    const { value } = this;
    const derived = this.derivedValue;

    return !value && !derived;
  }

  private hasChildren() {
    return !!this.resource.children;
  }
}

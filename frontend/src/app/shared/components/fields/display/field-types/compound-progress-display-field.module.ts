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

import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { DisplayField } from 'core-app/shared/components/fields/display/display-field.module';
import { InjectField } from 'core-app/shared/helpers/angular/inject-field.decorator';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import {
  uiStateLinkClass,
} from 'core-app/features/work-packages/components/wp-fast-table/builders/ui-state-link-builder';
import {
  HierarchyQueryLinkHelperService,
} from 'core-app/shared/components/fields/display/field-types/hierarchy-query-link-helper.service';
import { ExcludedIconHelperService } from 'core-app/shared/components/fields/display/field-types/excluded-icon-helper.service';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';

export class CompoundProgressDisplayField extends DisplayField {
  @InjectField() PathHelper:PathHelperService;

  @InjectField() apiV3Service:ApiV3Service;

  @InjectField() excludedIconHelperService:ExcludedIconHelperService;

  @InjectField() hierarchyQueryLinkHelper:HierarchyQueryLinkHelperService;

  private derivedText = this.I18n.t('js.label_value_derived_from_children');

  public render(element:HTMLElement, displayText:string):void {
    element.classList.add('split-time-field');
    element.setAttribute('title', displayText);

    this.renderActual(element, displayText);

    if (this.derivedValue !== null && this.hasChildren()) {
      this.renderSeparator(element);
      this.renderDerived(element, this.derivedValueString);
    }
  }

  private renderActual(element:HTMLElement, displayText:string):void {
    const span = document.createElement('span');

    span.textContent = displayText;
    span.title = this.valueString;
    span.classList.add('-actual-value');

    this.excludedIconHelperService.addIconIfExcludedFromTotals(span, this.resource as WorkPackageResource);

    element.appendChild(span);
  }

  private renderDerived(element:HTMLElement, displayText:string):void {
    const link = document.createElement('a');

    link.textContent = `Σ ${displayText}`;
    link.title = `${displayText} ${this.derivedText}`;
    link.classList.add('-derived-value', uiStateLinkClass);

    this.hierarchyQueryLinkHelper.addHref(link, this.resource);

    element.appendChild(link);
  }

  public renderSeparator(element:HTMLElement):void {
    const span = document.createElement('span');

    span.textContent = '·';
    span.classList.add('-separator');
    span.ariaHidden = 'true';

    element.appendChild(span);
  }

  public isEmpty():boolean {
    const { value } = this;
    const derived = this.derivedValue;

    return (value === null) && (derived === null);
  }

  public get value():number|null {
    return this.resource[this.name] as number|null;
  }

  public get valueString() {
    return this.formatAsPercentage(this.value);
  }

  private get derivedPropertyName():string {
    return `derived${_.upperFirst(this.name)}`;
  }

  private get derivedValue():number|null {
    return this.resource[this.derivedPropertyName] as number|null;
  }

  private get derivedValueString():string {
    return this.formatAsPercentage(this.derivedValue);
  }

  private formatAsPercentage(value:number|null) {
    if (value === null || value === undefined) {
      return this.placeholder;
    }
    return `${value}%`;
  }

  private hasChildren() {
    return !!this.resource.children;
  }
}

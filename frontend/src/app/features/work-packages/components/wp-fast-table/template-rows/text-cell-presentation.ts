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
// along with this program. If not, see <https://www.gnu.org/licenses/>.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { Injector } from '@angular/core';
import { SchemaCacheService } from 'core-app/core/schemas/schema-cache.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { DisplayField } from 'core-app/shared/components/fields/display/display-field.module';
import { DisplayFieldService, type DisplayFieldContextOptions } from 'core-app/shared/components/fields/display/display-field.service';
import {
  editableClassName, placeholderClassName, readOnlyClassName, requiredClassName,
} from 'core-app/shared/components/fields/display/display-field-renderer';
import { HighlightedResourceDisplayField } from 'core-app/shared/components/fields/display/field-types/highlighted-resource-display-field.module';
import { LinkDisplayField, type LinkDisplayPresentation } from 'core-app/shared/components/fields/display/field-types/link-display-field.module';
import { ResourceDisplayField } from 'core-app/shared/components/fields/display/field-types/resource-display-field.module';
import { HalResourceEditingService } from 'core-app/shared/components/fields/edit/services/hal-resource-editing.service';
import { WorkPackageViewBaselineService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-baseline.service';

export interface TextCellPresentation {
  attribute:string;
  displayClasses:string;
  text:string;
  title:string|null;
  label:string;
  link?:LinkDisplayPresentation|null;
}

export function textCellPresentation(
  injector:Injector,
  workPackage:WorkPackageResource,
  attribute:string,
  shouldHighlightInline?:DisplayFieldContextOptions['shouldHighlightInline'],
):TextCellPresentation|null {
  const editing = injector.get(HalResourceEditingService).typedState(workPackage);
  const schema = editing.value?.schema ?? injector.get(SchemaCacheService).of(workPackage);
  const mapped = schema.mappedName(attribute);
  const fieldSchema = schema.ofProperty(mapped);
  if (!fieldSchema || injector.get(WorkPackageViewBaselineService).isChanged(workPackage, mapped)) return null;
  const field = injector.get(DisplayFieldService).getField(workPackage, mapped, fieldSchema, {
    injector,
    container: 'table',
    options: { tabbable: false, shouldHighlightInline },
  });
  const highlighted = field instanceof HighlightedResourceDisplayField && field.render === HighlightedResourceDisplayField.prototype.render;
  const disclosed = field instanceof ResourceDisplayField && field.render === ResourceDisplayField.prototype.render && !field.isUndisclosed;
  const link = field instanceof LinkDisplayField && field.render === LinkDisplayField.prototype.render;
  if (field.isFormattable || !(field.render === DisplayField.prototype.render || highlighted || disclosed || link)) return null;

  const highlightClasses = highlighted ? field.inlineHighlightClasses : null;
  const empty = field.isEmpty();
  const editable = schema.isAttributeEditable(attribute);
  let displayClasses = `${attribute} ${editable ? editableClassName : readOnlyClassName}`;
  if (field.required) displayClasses += ` ${requiredClassName}`;
  if (empty) displayClasses += ` ${placeholderClassName}`;
  if (highlightClasses) displayClasses += ` ${highlightClasses}`;

  const labelEditable = mapped === attribute ? editable : schema.isAttributeEditable(mapped);
  const i18n = injector.get(I18nService);
  const name = `${field.displayName} ${empty ? i18n.t('js.inplace.null_value_label') : field.valueString}`;
  const presentation:TextCellPresentation = {
    attribute,
    displayClasses,
    text: String(empty ? field.placeholder : field.valueString),
    title: field.title === '' ? null : field.title,
    label: field.writable && labelEditable ? i18n.t('js.inplace.button_edit', { attribute: name }) : name,
  };
  if (link) presentation.link = field.linkPresentation;
  return presentation;
}

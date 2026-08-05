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
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { DisplayFieldService, DisplayFieldContext } from 'core-app/shared/components/fields/display/display-field.service';
import { DisplayField } from 'core-app/shared/components/fields/display/display-field.module';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { IFieldSchema } from 'core-app/shared/components/fields/field.base';
import {
  SingleLineResourcesDisplayField,
} from 'core-app/shared/components/fields/display/field-types/single-line-resources-display-field.module';
import {
  MultipleLinesCustomOptionsDisplayField,
} from 'core-app/shared/components/fields/display/field-types/multiple-lines-custom-options-display-field.module';
import {
  MultipleLinesUserFieldModule,
} from 'core-app/shared/components/fields/display/field-types/multiple-lines-user-display-field.module';
import {
  MultipleLinesHierarchyItemDisplayField,
} from 'core-app/shared/components/fields/display/field-types/multiple-lines-hierarchy-item-display-field.module';
import {
  SingleLineUserDisplayField,
} from 'core-app/shared/components/fields/display/field-types/single-line-user-display-field.module';
import { I18nService } from 'core-app/core/i18n/i18n.service';

type DisplayFieldClass = new (name:string, context:DisplayFieldContext) => DisplayField;

describe('DisplayFieldService', () => {
  const service = new DisplayFieldService();

  const mockI18n = { t: (key:string) => key };

  const serviceMap = new Map<unknown, unknown>([
    [I18nService, mockI18n],
  ]);

  const mockInjector = {
    get: (token:unknown, notFoundValue?:unknown) => serviceMap.get(token) ?? notFoundValue ?? {},
  };

  function fieldFor(type:string, layout?:string):DisplayField {
    const context = {
      injector: mockInjector,
      container: 'single-view',
      options: layout ? { layout } : {},
    } as unknown as DisplayFieldContext;

    return service.getField({} as HalResource, 'multiValueAttribute', { type } as IFieldSchema, context);
  }

  // Every type the singleline layout applies to, paired with the fields it
  // renders as in the single view for each layout. Users keep their avatar
  // rendering in the singleline layout via a dedicated field.
  const multiValueTypes:[string, DisplayFieldClass, DisplayFieldClass][] = [
    ['[]Version', SingleLineResourcesDisplayField, MultipleLinesCustomOptionsDisplayField],
    ['[]Category', SingleLineResourcesDisplayField, MultipleLinesCustomOptionsDisplayField],
    ['[]CustomOption', SingleLineResourcesDisplayField, MultipleLinesCustomOptionsDisplayField],
    ['[]User', SingleLineUserDisplayField, MultipleLinesUserFieldModule],
    ['[]CustomField::Hierarchy::Item', SingleLineResourcesDisplayField, MultipleLinesHierarchyItemDisplayField],
  ];

  multiValueTypes.forEach(([type, singlelineClass, multilineClass]) => {
    describe(`for schema type ${type}`, () => {
      it(`routes the singleline layout to ${singlelineClass.name}`, () => {
        expect(fieldFor(type, 'singleline')).toBeInstanceOf(singlelineClass);
      });

      it(`routes the multiline layout to ${multilineClass.name}`, () => {
        expect(fieldFor(type, 'multiline')).toBeInstanceOf(multilineClass);
      });

      it(`routes the default layout to ${multilineClass.name}`, () => {
        expect(fieldFor(type)).toBeInstanceOf(multilineClass);
      });
    });
  });
});

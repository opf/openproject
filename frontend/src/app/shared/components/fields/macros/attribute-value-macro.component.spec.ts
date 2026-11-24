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

import { CUSTOM_ELEMENTS_SCHEMA } from '@angular/core';
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { of } from 'rxjs';
import { onTestFinished, vi } from 'vitest';

import {
  ATTRIBUTE_MACRO_CLASS,
  AttributeValueMacroComponent,
} from 'core-app/shared/components/fields/macros/attribute-value-macro.component';
import { AttributeModelLoaderService } from 'core-app/shared/components/fields/macros/attribute-model-loader.service';
import { SchemaCacheService } from 'core-app/core/schemas/schema-cache.service';
import { DisplayFieldService } from 'core-app/shared/components/fields/display/display-field.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';

describe('AttributeValueMacroComponent', () => {
  let fixture:ComponentFixture<AttributeValueMacroComponent>;
  let requireResource:ReturnType<typeof vi.fn>;

  function render(
    dataset:Record<string, string>,
    resourceType = 'WorkPackage',
    parent?:HTMLElement,
  ):Promise<AttributeValueMacroComponent> {
    const resource = { _type: resourceType } as HalResource;
    requireResource = vi.fn(() => of(resource));

    const schema = {
      attributeFromLocalizedName: (name:string) => name,
    };

    const schemaProxy = {
      isMilestone: false,
      ofProperty: () => ({ type: '[]Version' }),
    };

    TestBed.configureTestingModule({
      declarations: [AttributeValueMacroComponent],
      schemas: [CUSTOM_ELEMENTS_SCHEMA],
      providers: [
        { provide: AttributeModelLoaderService, useValue: { require: requireResource } },
        { provide: SchemaCacheService, useValue: { ensureLoaded: () => Promise.resolve(schema), proxied: () => schemaProxy } },
        { provide: DisplayFieldService, useValue: {} },
        { provide: I18nService, useValue: { t: (key:string) => key } },
      ],
    });

    fixture = TestBed.createComponent(AttributeValueMacroComponent);
    const element = fixture.nativeElement as HTMLElement;
    Object.entries(dataset).forEach(([key, value]) => {
      element.dataset[key] = value;
    });
    parent?.append(element);

    fixture.detectChanges();
    return fixture.whenStable().then(() => fixture.componentInstance);
  }

  describe('with the deprecated version attribute on a work package', () => {
    it('maps to targetVersions with the singleline layout', async () => {
      const component = await render({ model: 'workPackage', id: '42', attribute: 'version' });

      expect(component.fieldName).toEqual('targetVersions');
      expect(component.layout).toEqual('singleline');
    });

    it('keeps an explicitly requested multiline layout', async () => {
      const component = await render({
        model: 'workPackage', id: '42', attribute: 'version', layout: 'multiline',
      });

      expect(component.fieldName).toEqual('targetVersions');
      expect(component.layout).toEqual('multiline');
    });
  });

  describe('with an attribute name that needs quoting in a selector', () => {
    it('renders the attribute', async () => {
      const component = await render({ model: 'workPackage', id: '42', attribute: 'Customer "VIP"' });

      expect(component.fieldName).toEqual('Customer "VIP"');
    });

    it('detects a macro nested in a macro for the same attribute', async () => {
      const ancestor = document.createElement('div');
      ancestor.classList.add(ATTRIBUTE_MACRO_CLASS);
      Object.assign(ancestor.dataset, { model: 'workPackage', id: '42', attribute: 'Customer "VIP"' });
      document.body.append(ancestor);
      onTestFinished(() => ancestor.remove());

      const component = await render({ model: 'workPackage', id: '42', attribute: 'Customer "VIP"' }, 'WorkPackage', ancestor);

      expect(component.error).toEqual('js.editor.macro.error');
      expect(requireResource).not.toHaveBeenCalled();
    });
  });

  describe('with a version attribute on another resource type', () => {
    it('keeps the attribute untouched', async () => {
      const component = await render({ model: 'project', id: '42', attribute: 'version' }, 'Project');

      expect(component.fieldName).toEqual('version');
      expect(component.layout).toBeUndefined();
    });
  });
});

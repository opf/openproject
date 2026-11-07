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
import { TestBed } from '@angular/core/testing';
import { SchemaCacheService } from 'core-app/core/schemas/schema-cache.service';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { WorkPackageViewBaselineService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-baseline.service';
import { DisplayFieldService } from 'core-app/shared/components/fields/display/display-field.service';
import { TextDisplayField } from 'core-app/shared/components/fields/display/field-types/text-display-field.module';
import { IntegerDisplayField } from 'core-app/shared/components/fields/display/field-types/integer-display-field.module';
import { LinkDisplayField } from 'core-app/shared/components/fields/display/field-types/link-display-field.module';
import { WorkPackageIdDisplayField } from 'core-app/shared/components/fields/display/field-types/wp-id-display-field.module';
import { ResourceDisplayField } from 'core-app/shared/components/fields/display/field-types/resource-display-field.module';
import { HalResourceEditingService } from 'core-app/shared/components/fields/edit/services/hal-resource-editing.service';
import { FakeDragAndDropService, harnessProviders } from '../testing/table-harness';
import { buildWorkPackage } from '../testing/work-package-fixture';
import { TextCellPresenter } from './text-cell-presentation';

class MappedResourceDisplayField extends ResourceDisplayField {
  protected override get attribute():unknown {
    return this.resource.project;
  }

  public override get title():string {
    return 'Project tooltip';
  }
}

class SpecializedResourceDisplayField extends ResourceDisplayField {
  public override render(element:HTMLElement, displayText:string):void {
    super.render(element, `${displayText}!`);
  }
}

class SpecializedLinkDisplayField extends LinkDisplayField {
  public override render(element:HTMLElement, displayText:string):void {
    super.render(element, `${displayText}!`);
  }
}

describe('text cell presentation', () => {
  function present(workPackage:WorkPackageResource, attribute:string) {
    const presenter = new TextCellPresenter(TestBed.inject(Injector));
    return presenter.present(workPackage, presenter.schemaFor(workPackage), attribute);
  }

  beforeEach(() => {
    TestBed.configureTestingModule({ providers: harnessProviders(new FakeDragAndDropService(), { workPackages: [], editing: {}, translations: { 'js.inplace.button_edit': 'Edit %{attribute}', 'js.inplace.null_value_label': 'No value' } }) });
    const fields = TestBed.inject(DisplayFieldService);
    fields.addFieldType(TextDisplayField, 'text', ['String']);
    fields.addFieldType(IntegerDisplayField, 'integer', ['Integer']);
  });

  it('keeps field labels, placeholders and editability for empty subject text', () => {
    const value = present(buildWorkPackage({ id: '1', subject: '' }), 'subject');
    expect(value).toMatchObject({ text: '-', title: null, label: 'Edit subject No value' });
    expect(value?.displayClasses.split(' ').sort()).toEqual(['-editable', '-placeholder', 'inline-edit--display-field', 'subject']);
  });

  it('renders zero instead of the empty placeholder', () => {
    const value = present(buildWorkPackage({ id: '0' }), 'id');
    expect(value).toMatchObject({ text: '0' });
    expect(value?.displayClasses.split(' ').sort()).toEqual(['-read-only', 'id', 'inline-edit--display-field']);
  });

  it('uses the active editing schema before consulting the schema cache', () => {
    const workPackage = buildWorkPackage({ id: '1', subject: 'Example' });
    const cache = TestBed.inject(SchemaCacheService);
    const schema = cache.of(workPackage);
    const fieldSchema = schema.ofProperty('subject');
    const editingSchema = Object.assign(schema, {
      ofProperty: () => ({ ...fieldSchema, required: true, name: 'Editing subject' }),
    });
    const editing = TestBed.inject(HalResourceEditingService);
    vi.spyOn(editing, 'typedState').mockReturnValue({
      value: { schema: editingSchema },
    } as unknown as ReturnType<HalResourceEditingService['typedState']>);
    const readCache = vi.spyOn(cache, 'of');

    const value = present(workPackage, 'subject');
    expect(value?.displayClasses).toContain('-required');
    expect(value?.label).toBe('Edit Editing subject Example');
    expect(readCache).not.toHaveBeenCalled();
  });

  it('keeps the schema of each table injector for the same work package', () => {
    const workPackage = buildWorkPackage({ id: '1', subject: 'Example' });
    const parent = TestBed.inject(Injector);
    const cache = parent.get(SchemaCacheService);
    const presenterFor = (name:string) => {
      const schema = cache.of(workPackage);
      const fieldSchema = schema.ofProperty('subject');
      const localSchema = Object.assign(schema, { ofProperty: () => ({ ...fieldSchema, name }) });
      return new TextCellPresenter(Injector.create({
        parent,
        providers: [{ provide: SchemaCacheService, useValue: { of: () => localSchema } }],
      }));
    };
    const first = presenterFor('First subject');
    const second = presenterFor('Second subject');

    expect(first.present(workPackage, first.schemaFor(workPackage), 'subject')?.label).toBe('Edit First subject Example');
    expect(second.present(workPackage, second.schemaFor(workPackage), 'subject')?.label).toBe('Edit Second subject Example');
    expect(first.present(workPackage, first.schemaFor(workPackage), 'subject')?.label).toBe('Edit First subject Example');
  });

  it('keeps specialized link fields and baseline changes on their existing rendering path', () => {
    TestBed.inject(DisplayFieldService).addFieldType(WorkPackageIdDisplayField, 'wp-id', ['Integer']);
    expect(present(buildWorkPackage({ id: '1' }), 'id')).toBeNull();
    vi.spyOn(TestBed.inject(WorkPackageViewBaselineService), 'isChanged').mockReturnValue(true);
    expect(present(buildWorkPackage({ id: '1' }), 'subject')).toBeNull();
  });

  it('uses the mapped resource attribute and its independent title', () => {
    TestBed.inject(DisplayFieldService).addFieldType(MappedResourceDisplayField, 'resource', ['String']);
    const workPackage = buildWorkPackage({ id: '1', subject: 'Other text', attributes: { project: { name: 'Mapped project' } } });
    const cache = TestBed.inject(SchemaCacheService);
    const schema = cache.of(workPackage);
    vi.spyOn(cache, 'of').mockReturnValue(Object.assign(schema, { mappedName: () => 'subject' }));

    const value = present(workPackage, 'project');
    expect(value).toMatchObject({
      attribute: 'project', text: 'Mapped project', title: 'Project tooltip', label: 'Edit subject Mapped project',
    });
    expect(value?.displayClasses.split(' ')).toContain('-read-only');
  });

  it('keeps an overridden resource renderer on its existing rendering path', () => {
    TestBed.inject(DisplayFieldService).addFieldType(SpecializedResourceDisplayField, 'resource', ['String']);
    const workPackage = buildWorkPackage({ id: '1', attributes: { subject: { name: 'Specialized resource' } } });
    expect(present(workPackage, 'subject')).toBeNull();
  });

  it('keeps an overridden link renderer on its existing rendering path', () => {
    TestBed.inject(DisplayFieldService).addFieldType(SpecializedLinkDisplayField, 'link', ['String']);
    const workPackage = buildWorkPackage({ id: '1', subject: '/help' });
    expect(present(workPackage, 'subject')).toBeNull();
  });
});

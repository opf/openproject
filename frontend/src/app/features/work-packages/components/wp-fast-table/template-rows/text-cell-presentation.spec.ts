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
import { WorkPackageViewBaselineService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-baseline.service';
import { DisplayFieldService } from 'core-app/shared/components/fields/display/display-field.service';
import { TextDisplayField } from 'core-app/shared/components/fields/display/field-types/text-display-field.module';
import { IntegerDisplayField } from 'core-app/shared/components/fields/display/field-types/integer-display-field.module';
import { WorkPackageIdDisplayField } from 'core-app/shared/components/fields/display/field-types/wp-id-display-field.module';
import { ResourceDisplayField } from 'core-app/shared/components/fields/display/field-types/resource-display-field.module';
import { FakeDragAndDropService, harnessProviders } from '../testing/table-harness';
import { buildWorkPackage } from '../testing/work-package-fixture';
import { textCellPresentation } from './text-cell-presentation';

class MappedResourceDisplayField extends ResourceDisplayField {
  protected override get attribute():unknown {
    return this.resource.project;
  }
}

class SpecializedResourceDisplayField extends ResourceDisplayField {
  public override render(element:HTMLElement, displayText:string):void {
    super.render(element, `${displayText}!`);
  }
}

 describe('text cell presentation', () => {
  beforeEach(() => {
    TestBed.configureTestingModule({ providers: harnessProviders(new FakeDragAndDropService(), { workPackages: [], editing: {}, translations: { 'js.inplace.button_edit': 'Edit %{attribute}', 'js.inplace.null_value_label': 'No value' } }) });
    const fields = TestBed.inject(DisplayFieldService);
    fields.addFieldType(TextDisplayField, 'text', ['String']);
    fields.addFieldType(IntegerDisplayField, 'integer', ['Integer']);
  });

  it('keeps field labels, placeholders and editability for empty subject text', () => {
    const value = textCellPresentation(TestBed.inject(Injector), buildWorkPackage({ id: '1', subject: '' }), 'subject');
    expect(value).toMatchObject({ text: '-', empty: true, editable: true, label: 'Edit subject No value' });
  });

  it('renders zero instead of the empty placeholder', () => {
    const value = textCellPresentation(TestBed.inject(Injector), buildWorkPackage({ id: '0' }), 'id');
    expect(value).toMatchObject({ text: '0', empty: false });
  });

  it('keeps specialized link fields and baseline changes on their existing rendering path', () => {
    TestBed.inject(DisplayFieldService).addFieldType(WorkPackageIdDisplayField, 'wp-id', ['Integer']);
    expect(textCellPresentation(TestBed.inject(Injector), buildWorkPackage({ id: '1' }), 'id')).toBeNull();
    vi.spyOn(TestBed.inject(WorkPackageViewBaselineService), 'isChanged').mockReturnValue(true);
    expect(textCellPresentation(TestBed.inject(Injector), buildWorkPackage({ id: '1' }), 'subject')).toBeNull();
  });

  it('uses the mapped resource field and its attribute getter', () => {
    TestBed.inject(DisplayFieldService).addFieldType(MappedResourceDisplayField, 'resource', ['String']);
    const workPackage = buildWorkPackage({ id: '1', subject: 'Other text', attributes: { project: { name: 'Mapped project' } } });
    const cache = TestBed.inject(SchemaCacheService);
    const schema = cache.of(workPackage);
    vi.spyOn(cache, 'of').mockReturnValue(Object.assign(schema, { mappedName: () => 'subject' }));

    expect(textCellPresentation(TestBed.inject(Injector), workPackage, 'project')).toMatchObject({
      attribute: 'project', text: 'Mapped project', title: 'Mapped project', label: 'Edit subject Mapped project', editable: false,
    });
  });

  it('keeps an overridden resource renderer on its existing rendering path', () => {
    TestBed.inject(DisplayFieldService).addFieldType(SpecializedResourceDisplayField, 'resource', ['String']);
    const workPackage = buildWorkPackage({ id: '1', attributes: { subject: { name: 'Specialized resource' } } });
    expect(textCellPresentation(TestBed.inject(Injector), workPackage, 'subject')).toBeNull();
  });
});

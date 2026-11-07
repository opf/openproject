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
import { CurrentProjectService } from 'core-app/core/current-project/current-project.service';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { SchemaCacheService } from 'core-app/core/schemas/schema-cache.service';
import { KeepTabService } from 'core-app/features/work-packages/components/wp-single-view-tabs/keep-tab/keep-tab.service';
import { WorkPackageIdDisplayField } from 'core-app/shared/components/fields/display/field-types/wp-id-display-field.module';
import { FakeDragAndDropService, harnessProviders } from '../testing/table-harness';
import { buildWorkPackage } from '../testing/work-package-fixture';
import { IdCellPresenter } from './id-cell-presenter';

describe('ID cell presentation', () => {
  beforeEach(() => {
    TestBed.configureTestingModule({
      providers: [
        ...harnessProviders(new FakeDragAndDropService(), { workPackages: [] }),
        { provide: PathHelperService, useValue: { genericWorkPackagePath: (project:string|null, id:string, tab:string) => `/${project ?? 'work_packages'}/${id}/${tab}` } },
      ],
    });
  });

  it('returns independent A/B/A snapshots while reusing the field instance', () => {
    const presenter = new IdCellPresenter(TestBed.inject(Injector));
    const apply = vi.spyOn(WorkPackageIdDisplayField.prototype, 'apply');
    const cache = TestBed.inject(SchemaCacheService);
    const schemaOf = cache.of.bind(cache);
    vi.spyOn(cache, 'of').mockImplementation((workPackage) => {
      const schema = schemaOf(workPackage);
      const ofProperty = schema.ofProperty.bind(schema);
      return Object.assign(schema, {
        ofProperty: (attribute:string) => ({
          ...ofProperty(attribute), name: workPackage.id === '42' ? 'First ID' : 'Second ID', required: workPackage.id === '42',
        }),
      });
    });
    const a = Object.assign(buildWorkPackage({ id: '42' }), { displayId: 'DEMO-7' });
    const b = buildWorkPackage({ id: '43' });

    const first = presenter.present(a);
    const second = presenter.present(b);
    const again = presenter.present(a);

    expect(first).toEqual({ text: 'DEMO-7', title: 'DEMO-7', label: 'First ID DEMO-7', required: true, href: `/work_packages/DEMO-7/activity${window.location.search}` });
    expect(second).toEqual({ text: '43', title: '43', label: 'Second ID 43', required: false, href: `/work_packages/43/activity${window.location.search}` });
    expect(again).toEqual(first);
    expect(again).not.toBe(first);
    expect(apply).toHaveBeenCalledTimes(3);
    expect(new Set(apply.mock.contexts).size).toBe(1);
  });

  it('leaves a missing schema or new work package without a link after a valid field', () => {
    const presenter = new IdCellPresenter(TestBed.inject(Injector));
    const cache = TestBed.inject(SchemaCacheService);
    const schemaOf = cache.of.bind(cache);
    vi.spyOn(cache, 'of').mockImplementation((workPackage) => {
      const schema = schemaOf(workPackage);
      return workPackage.id === '43' ? Object.assign(schema, { ofProperty: () => undefined }) : schema;
    });
    const existing = buildWorkPackage({ id: '42' });
    const valid = presenter.present(existing);

    expect(presenter.present(buildWorkPackage({ id: '43' }))).toEqual({ text: '', title: null, label: null, required: false, href: null });
    expect(presenter.present(existing)).toEqual(valid);
    expect(presenter.present(buildWorkPackage({ id: 'new' }))).toMatchObject({ text: '', href: null });
    const draft = Object.assign(buildWorkPackage({ id: 'new' }), { displayId: 'DEMO-NEW' });
    expect(presenter.present(draft)).toMatchObject({ text: '', title: 'DEMO-NEW', label: 'ID DEMO-NEW', href: null });
    expect(presenter.present(existing)).toEqual(valid);
  });

  it('keeps project and live tab state scoped to its injector', () => {
    const routeContext = (identifier:string, tab:string) => {
      const keepTab = { currentShowTab: tab };
      const injector = Injector.create({
        parent: TestBed.inject(Injector),
        providers: [
          { provide: CurrentProjectService, useValue: { identifier } },
          { provide: KeepTabService, useValue: keepTab },
        ],
      });
      return { keepTab, presenter: new IdCellPresenter(injector) };
    };
    const first = routeContext('project-a', 'activity');
    const second = routeContext('project-b', 'overview');
    const workPackage = Object.assign(buildWorkPackage({ id: '42' }), { displayId: 'DEMO-7' });
    const initial = first.presenter.present(workPackage);
    expect(initial.href).toBe(`/project-a/DEMO-7/activity${window.location.search}`);
    expect(second.presenter.present(workPackage).href).toBe(`/project-b/DEMO-7/overview${window.location.search}`);

    first.keepTab.currentShowTab = 'relations';

    expect(first.presenter.present(workPackage).href).toBe(`/project-a/DEMO-7/relations${window.location.search}`);
    expect(initial.href).toBe(`/project-a/DEMO-7/activity${window.location.search}`);
    expect(second.presenter.present(workPackage).href).toBe(`/project-b/DEMO-7/overview${window.location.search}`);
  });
});

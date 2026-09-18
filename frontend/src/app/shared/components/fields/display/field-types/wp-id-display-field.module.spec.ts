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

import { WorkPackageIdDisplayField } from './wp-id-display-field.module';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { KeepTabService } from 'core-app/features/work-packages/components/wp-single-view-tabs/keep-tab/keep-tab.service';
import { CurrentProjectService } from 'core-app/core/current-project/current-project.service';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { UrlParamsService } from 'core-app/core/navigation/url-params.service';
import { DisplayFieldContext } from 'core-app/shared/components/fields/display/display-field.service';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { IFieldSchema } from 'core-app/shared/components/fields/field.base';

describe('WorkPackageIdDisplayField', () => {
  let field:WorkPackageIdDisplayField;

  const mockI18n = { t: (key:string) => key };
  const mockKeepTab = { currentShowTab: 'activity' };
  const mockCurrentProject = { identifier: 'my-project' };
  const mockPathHelper = {
    genericWorkPackagePath: (_proj:string | null, wpId:string, _tab:string) => `/work_packages/${wpId}`,
  };
  const mockUrlParams = {
    basePathWithoutDetails: () => '/work_packages',
  };

  const serviceMap = new Map<unknown, unknown>([
    [I18nService, mockI18n],
    [KeepTabService, mockKeepTab],
    [CurrentProjectService, mockCurrentProject],
    [PathHelperService, mockPathHelper],
    [UrlParamsService, mockUrlParams],
  ]);

  function buildField(resourceAttrs:Record<string, unknown> = {}) {
    const resource = {
      id: '42',
      displayId: 'PROJ-7',
      ...resourceAttrs,
    } as unknown as HalResource;

    const mockInjector = {
      get: (token:unknown, notFoundValue?:unknown) => serviceMap.get(token) ?? notFoundValue ?? {},
    };

    field = new WorkPackageIdDisplayField('id', {
      injector: mockInjector,
      container: null,
      options: {},
    } as unknown as DisplayFieldContext);

    field.apply(resource, { type: 'Integer' } as IFieldSchema);
  }

  describe('valueString', () => {
    it('returns the semantic displayId when present on the resource', () => {
      buildField({ id: '42', displayId: 'PROJ-7' });

      expect(field.valueString).toEqual('PROJ-7');
    });

    it('falls back to numeric id when displayId is absent', () => {
      buildField({ id: '42', displayId: undefined });

      expect(field.valueString).toEqual('42');
    });
  });

  describe('render', () => {
    it('renders the displayText as visible link content, not the numeric id', () => {
      buildField({ id: '42', displayId: 'PROJ-7' });

      const container = document.createElement('span');
      field.render(container, 'PROJ-7');

      const link = container.querySelector('a');

      expect(link).toBeTruthy();
      expect(link!.textContent).toEqual('PROJ-7');
    });

    it('uses the semantic displayId in the href for pretty URLs', () => {
      buildField({ id: '42', displayId: 'PROJ-7' });

      const container = document.createElement('span');
      field.render(container, 'PROJ-7');

      const link = container.querySelector('a');

      expect(link).toBeTruthy();
      expect(link!.href).toContain('/work_packages/PROJ-7');
    });

    it('keeps the numeric id in data-work-package-id for selection', () => {
      buildField({ id: '42', displayId: 'PROJ-7' });

      const container = document.createElement('span');
      field.render(container, 'PROJ-7');

      const link = container.querySelector('a');

      expect(link).toBeTruthy();
      expect(link!.dataset.workPackageId).toEqual('42');
    });
  });
});

import { WorkPackageIdDisplayField } from './wp-id-display-field.module';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { StateService } from '@uirouter/core';
import { KeepTabService } from 'core-app/features/work-packages/components/wp-single-view-tabs/keep-tab/keep-tab.service';
import { CurrentProjectService } from 'core-app/core/current-project/current-project.service';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { DisplayFieldContext } from 'core-app/shared/components/fields/display/display-field.service';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { IFieldSchema } from 'core-app/shared/components/fields/field.base';

describe('WorkPackageIdDisplayField', () => {
  let field:WorkPackageIdDisplayField;

  const mockI18n = { t: (key:string) => key };
  const mockState = {};
  const mockKeepTab = { currentShowTab: 'activity' };
  const mockCurrentProject = { identifier: 'my-project' };
  const mockPathHelper = {
    genericWorkPackagePath: (_proj:string | null, wpId:string, _tab:string) => `/work_packages/${wpId}`,
  };

  const serviceMap = new Map<unknown, unknown>([
    [I18nService, mockI18n],
    [StateService, mockState],
    [KeepTabService, mockKeepTab],
    [CurrentProjectService, mockCurrentProject],
    [PathHelperService, mockPathHelper],
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

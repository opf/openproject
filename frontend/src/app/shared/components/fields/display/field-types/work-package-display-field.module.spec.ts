import { WorkPackageDisplayField } from './work-package-display-field.module';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { DisplayFieldContext } from 'core-app/shared/components/fields/display/display-field.service';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { IFieldSchema } from 'core-app/shared/components/fields/field.base';
import { Injector } from '@angular/core';

describe('WorkPackageDisplayField', () => {
  let field:WorkPackageDisplayField;

  const mockI18n = { t: (key:string) => key };

  const serviceMap = new Map<unknown, unknown>([
    [I18nService, mockI18n],
  ]);

  function buildField(parentAttrs:Record<string, unknown> | null) {
    const resource = {
      parent: parentAttrs,
    } as unknown as HalResource;

    const mockInjector = {
      get: (token:unknown, notFoundValue?:unknown) => serviceMap.get(token) ?? notFoundValue ?? {},
    } as Injector;

    field = new WorkPackageDisplayField('parent', {
      injector: mockInjector,
      container: null,
      options: {},
    } as unknown as DisplayFieldContext);

    field.apply(resource, { type: 'WorkPackage' } as IFieldSchema);
  }

  describe('wpFormattedId', () => {
    it('returns the semantic ID from a fully loaded linked WP', () => {
      buildField({
        $loaded: true,
        id: '123',
        formattedId: 'PROJ-42',
        displayId: 'PROJ-42',
        href: '/api/v3/work_packages/123',
      });

      expect(field.wpFormattedId).toEqual('PROJ-42');
    });

    it('returns the semantic ID from an unloaded linked WP when displayId is on the link', () => {
      buildField({
        $loaded: false,
        formattedId: 'PROJ-42',
        displayId: 'PROJ-42',
        href: '/api/v3/work_packages/123',
      });

      expect(field.wpFormattedId).toEqual('PROJ-42');
    });

    it('falls back to prefixed numeric ID from an unloaded linked WP without displayId', () => {
      buildField({
        $loaded: false,
        formattedId: '#123',
        displayId: '123',
        href: '/api/v3/work_packages/123',
      });

      expect(field.wpFormattedId).toEqual('#123');
    });

    it('returns empty string when the linked WP is absent', () => {
      buildField(null);

      expect(field.wpFormattedId).toEqual('');
    });
  });

  describe('wpRoutingId', () => {
    it('returns the semantic displayId from a fully loaded linked WP', () => {
      buildField({
        $loaded: true,
        id: '123',
        displayId: 'PROJ-42',
        href: '/api/v3/work_packages/123',
      });

      expect(field.wpRoutingId).toEqual('PROJ-42');
    });

    it('returns the semantic displayId from an unloaded linked WP when displayId is on the link', () => {
      buildField({
        $loaded: false,
        displayId: 'PROJ-42',
        href: '/api/v3/work_packages/123',
      });

      expect(field.wpRoutingId).toEqual('PROJ-42');
    });

    it('falls back to numeric displayId from an unloaded linked WP without semantic displayId', () => {
      buildField({
        $loaded: false,
        displayId: '123',
        href: '/api/v3/work_packages/123',
      });

      expect(field.wpRoutingId).toEqual('123');
    });
  });
});

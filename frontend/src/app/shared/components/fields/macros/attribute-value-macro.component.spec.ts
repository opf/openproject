import { CUSTOM_ELEMENTS_SCHEMA } from '@angular/core';
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { of } from 'rxjs';

import { AttributeValueMacroComponent } from 'core-app/shared/components/fields/macros/attribute-value-macro.component';
import { AttributeModelLoaderService } from 'core-app/shared/components/fields/macros/attribute-model-loader.service';
import { SchemaCacheService } from 'core-app/core/schemas/schema-cache.service';
import { DisplayFieldService } from 'core-app/shared/components/fields/display/display-field.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';

describe('AttributeValueMacroComponent', () => {
  let fixture:ComponentFixture<AttributeValueMacroComponent>;

  function render(dataset:Record<string, string>, resourceType = 'WorkPackage'):Promise<AttributeValueMacroComponent> {
    const resource = { _type: resourceType } as HalResource;

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
        { provide: AttributeModelLoaderService, useValue: { require: () => of(resource) } },
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

  describe('with a version attribute on another resource type', () => {
    it('keeps the attribute untouched', async () => {
      const component = await render({ model: 'project', id: '42', attribute: 'version' }, 'Project');

      expect(component.fieldName).toEqual('version');
      expect(component.layout).toBeUndefined();
    });
  });
});

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
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++    Ng1FieldControlsWrapper,

import {
  ChangeDetectionStrategy,
  ChangeDetectorRef,
  Component,
  ElementRef,
  HostBinding,
  Injector,
  OnInit,
  ViewChild,
} from '@angular/core';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { SchemaCacheService } from 'core-app/core/schemas/schema-cache.service';
import {
  HalResourceEditingService,
} from 'core-app/shared/components/fields/edit/services/hal-resource-editing.service';
import { DisplayFieldService } from 'core-app/shared/components/fields/display/display-field.service';
import { IFieldSchema } from 'core-app/shared/components/fields/field.base';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import {
  AttributeModelLoaderService,
  SupportedAttributeModels,
} from 'core-app/shared/components/fields/macros/attribute-model-loader.service';
import { firstValueFrom } from 'rxjs';
import { ISchemaProxy } from 'core-app/features/hal/schemas/schema-proxy';

export const ATTRIBUTE_MACRO_CLASS = 'op-attribute-value-macro';

@Component({
  templateUrl: './attribute-value-macro.html',
  styleUrls: ['./attribute-macro.sass'],
  changeDetection: ChangeDetectionStrategy.OnPush,
  providers: [
    HalResourceEditingService,
  ],
})
export class AttributeValueMacroComponent implements OnInit {
  @ViewChild('displayContainer') private displayContainer:ElementRef<HTMLSpanElement>;

  // Whether the value could not be loaded
  error:string|null = null;

  text = {
    help: this.I18n.t('js.editor.macro.attribute_reference.macro_help_tooltip'),
    placeholder: this.I18n.t('js.placeholders.default'),
    not_found: this.I18n.t('js.editor.macro.attribute_reference.not_found'),
    invalid_attribute: (attr:string) => this.I18n.t('js.editor.macro.attribute_reference.invalid_attribute', { name: attr }),
  };

  @HostBinding('title') hostTitle = this.text.help;

  resource:HalResource;

  fieldName:string;

  constructor(
    readonly elementRef:ElementRef,
    readonly injector:Injector,
    readonly resourceLoader:AttributeModelLoaderService,
    readonly schemaCache:SchemaCacheService,
    readonly displayField:DisplayFieldService,
    readonly I18n:I18nService,
    readonly cdRef:ChangeDetectorRef,
  ) {
  }

  ngOnInit():void {
    const element = this.elementRef.nativeElement as HTMLElement;
    const model = element.dataset.model as SupportedAttributeModels;
    const id = element.dataset.id as string;
    const attributeName = element.dataset.attribute as string;
    element.classList.add(ATTRIBUTE_MACRO_CLASS);

    if (this.isNestedMacro(model, id, attributeName)) {
      const error = this.I18n.t('js.editor.macro.attribute_reference.nested_macro', { model, id });
      this.markError(error);
    } else {
      void this.loadAndRender(model, id, attributeName);
    }
  }

  private isNestedMacro(model:SupportedAttributeModels, id:string, attributeName:string):boolean {
    const element = this.elementRef.nativeElement as HTMLElement;
    const parent = element.parentElement;
    return !!parent?.closest(`.${ATTRIBUTE_MACRO_CLASS}[data-model="${model}"][data-id="${id}"][data-attribute="${attributeName}"]`);
  }

  private async loadAndRender(model:SupportedAttributeModels, id:string, attributeName:string):Promise<void> {
    let resource:HalResource|null;

    try {
      resource = await firstValueFrom(this.resourceLoader.require(model, id));
    } catch (e) {
      // eslint-disable-next-line @typescript-eslint/restrict-template-expressions
      console.error(`Failed to render macro ${e}`);
      this.markError(this.text.not_found);
      return;
    }

    if (!resource) {
      this.markError(this.text.not_found);
      return;
    }

    const schema = await this.schemaCache.ensureLoaded(resource);
    const proxied = this.schemaCache.proxied(resource, schema);
    const attribute = schema.attributeFromLocalizedName(attributeName) || this.dateAttribute(resource, proxied, attributeName);
    const fieldSchema = proxied.ofProperty(attribute) as IFieldSchema|undefined;

    if (fieldSchema) {
      this.resource = resource;
      this.fieldName = attribute;
    } else {
      this.markError(this.text.invalid_attribute(attributeName));
    }

    this.cdRef.detectChanges();
  }

  markError(message:string) {
    this.error = this.I18n.t('js.editor.macro.error', { message });
    this.cdRef.detectChanges();
  }

  dateAttribute(resource:HalResource, proxied:ISchemaProxy, attributeName:string):string {
    if (resource._type === 'WorkPackage' && !proxied.isMilestone && attributeName === 'date') {
      return 'combinedDate';
    }

    return proxied.mappedName(attributeName);
  }
}

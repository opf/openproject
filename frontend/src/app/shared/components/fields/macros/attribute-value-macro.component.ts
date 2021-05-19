//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2021 the OpenProject GmbH
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
// See docs/COPYRIGHT.rdoc for more details.
//++    Ng1FieldControlsWrapper,

import {
  ChangeDetectionStrategy,
  ChangeDetectorRef,
  Component,
  ElementRef,
  HostBinding,
  Injector,
  ViewChild
} from "@angular/core";
import { HalResource } from "core-app/core/hal/resources/hal-resource";
import { APIV3Service } from "core-app/core/apiv3/api-v3.service";
import { NEVER, Observable } from "rxjs";
import { filter, map, take, tap } from "rxjs/operators";
import { SchemaCacheService } from "core-components/schemas/schema-cache.service";
import { HalResourceEditingService } from "core-app/shared/components/fields/edit/services/hal-resource-editing.service";
import { DisplayFieldService } from "core-app/shared/components/fields/display/display-field.service";
import { IFieldSchema } from "core-app/shared/components/fields/field.base";
import { I18nService } from "core-app/core/i18n/i18n.service";
import {
  AttributeModelLoaderService,
  SupportedAttributeModels
} from "core-app/shared/components/fields/macros/attribute-model-loader.service";

export const attributeValueMacro = 'macro.macro--attribute-value';

@Component({
  selector: attributeValueMacro,
  templateUrl: './attribute-value-macro.html',
  styleUrls: ['./attribute-macro.sass'],
  changeDetection: ChangeDetectionStrategy.OnPush,
  providers: [
    HalResourceEditingService
  ]
})
export class AttributeValueMacroComponent {
  @ViewChild('displayContainer') private displayContainer:ElementRef<HTMLSpanElement>;

  // Whether the value could not be loaded
  error:string|null = null;

  text = {
    help: this.I18n.t('js.editor.macro.attribute_reference.macro_help_tooltip'),
    placeholder: this.I18n.t('js.placeholders.default'),
    not_found: this.I18n.t('js.editor.macro.attribute_reference.not_found'),
    invalid_attribute: (attr:string) =>
      this.I18n.t('js.editor.macro.attribute_reference.invalid_attribute', { name: attr }),
  };

  @HostBinding('title') hostTitle = this.text.help;

  resource:HalResource;
  fieldName:string;

  constructor(readonly elementRef:ElementRef,
              readonly injector:Injector,
              readonly resourceLoader:AttributeModelLoaderService,
              readonly schemaCache:SchemaCacheService,
              readonly displayField:DisplayFieldService,
              readonly I18n:I18nService,
              readonly cdRef:ChangeDetectorRef) {

  }

  ngOnInit() {
    const element = this.elementRef.nativeElement as HTMLElement;
    const model:SupportedAttributeModels = element.dataset.model as any;
    const id:string = element.dataset.id!;
    const attributeName:string = element.dataset.attribute!;

    this.loadAndRender(model, id, attributeName);
  }

  private async loadAndRender(model:SupportedAttributeModels, id:string, attributeName:string) {
    let resource:HalResource|null;

    try {
      resource = await this.resourceLoader.require(model, id);
    } catch (e) {
      console.error("Failed to render macro " + e);
      return this.markError(this.text.not_found);
    }

    if (!resource) {
      this.markError(this.text.not_found);
      return;
    }

    const schema = await this.schemaCache.ensureLoaded(resource);
    const attribute = schema.attributeFromLocalizedName(attributeName) || attributeName;
    const fieldSchema = schema[attribute] as IFieldSchema|undefined;

    if (fieldSchema) {
      this.resource = resource;
      this.fieldName = attribute;
    } else {
      this.markError(this.text.invalid_attribute(attributeName));
    }

    this.cdRef.detectChanges();
  }

  markError(message:string) {
    this.error = this.I18n.t('js.editor.macro.error', { message: message });
    this.cdRef.detectChanges();
  }
}

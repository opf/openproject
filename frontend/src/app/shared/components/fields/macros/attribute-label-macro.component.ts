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
} from '@angular/core';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { SchemaCacheService } from 'core-app/core/schemas/schema-cache.service';
import {
  HalResourceEditingService,
} from 'core-app/shared/components/fields/edit/services/hal-resource-editing.service';
import { DisplayFieldService } from 'core-app/shared/components/fields/display/display-field.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import {
  AttributeModelLoaderService,
  SupportedAttributeModels,
} from 'core-app/shared/components/fields/macros/attribute-model-loader.service';
import { capitalize } from 'core-app/shared/helpers/string-helpers';
import { firstValueFrom } from 'rxjs';

@Component({
  templateUrl: './attribute-label-macro.html',
  styleUrls: ['./attribute-macro.sass'],
  changeDetection: ChangeDetectionStrategy.OnPush,
  providers: [
    HalResourceEditingService,
  ],
})
export class AttributeLabelMacroComponent implements OnInit {
  // Whether the value could not be loaded
  error:string|null = null;

  text = {
    help: this.I18n.t('js.editor.macro.attribute_reference.macro_help_tooltip'),
    not_found: this.I18n.t('js.editor.macro.attribute_reference.not_found'),
    invalid_attribute: (attr:string) => this.I18n.t('js.editor.macro.attribute_reference.invalid_attribute', { name: attr }),
  };

  @HostBinding('title') hostTitle = this.text.help;

  // The loaded resource, required for help text
  resource:HalResource|null = null;

  // The scope to load for attribute help text
  attributeScope:string;

  // The attribute name, normalized from schema
  attribute:string;

  // The label to render
  label:string|undefined;

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
    this.attributeScope = capitalize(model);

    void this.loadResourceAttribute(model, id, attributeName);
  }

  private async loadResourceAttribute(model:SupportedAttributeModels, id:string, attributeName:string):Promise<void> {
    try {
      this.resource = await firstValueFrom(this.resourceLoader.require(model, id));
    } catch (e) {
      console.error('Failed to render macro %O', e);
      this.markError(this.text.not_found);
      return;
    }

    if (!this.resource) {
      this.markError(this.text.not_found);
      return;
    }

    const schema = await this.schemaCache.ensureLoaded(this.resource);
    this.attribute = schema.attributeFromLocalizedName(attributeName) || attributeName;
    this.label = (schema[this.attribute] as IOPFieldSchema|undefined)?.name;

    if (!this.label) {
      this.markError(this.text.invalid_attribute(attributeName));
    }

    this.cdRef.detectChanges();
  }

  markError(message:string) {
    this.error = this.I18n.t('js.editor.macro.error', { message });
    this.cdRef.detectChanges();
  }
}

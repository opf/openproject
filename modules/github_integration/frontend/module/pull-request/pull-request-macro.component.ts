// -- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2023 the OpenProject GmbH
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
// ++    Ng1FieldControlsWrapper,

import {
  ChangeDetectionStrategy,
  ChangeDetectorRef,
  Component,
  ElementRef,
  HostBinding,
  Injector,
  Input,
} from '@angular/core';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { SchemaCacheService } from 'core-app/core/schemas/schema-cache.service';
import { HalResourceEditingService } from 'core-app/shared/components/fields/edit/services/hal-resource-editing.service';
import { DisplayFieldService } from 'core-app/shared/components/fields/display/display-field.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import {
  AttributeModelLoaderService,
  SupportedAttributeModels,
} from 'core-app/shared/components/fields/macros/attribute-model-loader.service';
import { capitalize } from 'core-app/shared/helpers/string-helpers';
import { populateInputsFromDataset } from 'core-app/shared/components/dataset-inputs';

export const githubPullRequestMacroSelector = 'macro.github-pull-request';

@Component({
  selector: githubPullRequestMacroSelector,
  templateUrl: './pull-request-macro.component.html',
  styleUrls: ['./pull-request-macro.component.sass'],
  changeDetection: ChangeDetectionStrategy.OnPush,
  providers: [
    HalResourceEditingService,
  ],
})
export class PullRequestMacroComponent {
  @Input() pullRequestId:string;

  constructor(
    readonly elementRef:ElementRef,
    readonly injector:Injector,
    readonly resourceLoader:AttributeModelLoaderService,
    readonly schemaCache:SchemaCacheService,
    readonly displayField:DisplayFieldService,
    readonly I18n:I18nService,
    readonly cdRef:ChangeDetectorRef) {
    populateInputsFromDataset(this);
  }

  ngOnInit() {
    const element = this.elementRef.nativeElement as HTMLElement;
    const model:SupportedAttributeModels = element.dataset.model as any;
    const id:string = element.dataset.id!;
    const attributeName:string = element.dataset.attribute!;
    this.attributeScope = capitalize(model);

    this.loadResourceAttribute(model, id, attributeName);
  }

  private async loadResourceAttribute(model:SupportedAttributeModels, id:string, attributeName:string) {
    let resource:HalResource|null;

    try {
      this.resource = resource = await this.resourceLoader.require(model, id);
    } catch (e) {
      console.error(`Failed to render macro ${e}`);
      return this.markError(this.text.not_found);
    }

    if (!resource) {
      this.markError(this.text.not_found);
      return;
    }

    const schema = await this.schemaCache.ensureLoaded(resource);
    this.attribute = schema.attributeFromLocalizedName(attributeName) || attributeName;
    this.label = schema[this.attribute]?.name;

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

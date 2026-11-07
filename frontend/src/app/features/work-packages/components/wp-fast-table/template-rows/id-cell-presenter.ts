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
import { SchemaCacheService } from 'core-app/core/schemas/schema-cache.service';
import { CurrentProjectService } from 'core-app/core/current-project/current-project.service';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { UrlParamsService } from 'core-app/core/navigation/url-params.service';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { KeepTabService } from 'core-app/features/work-packages/components/wp-single-view-tabs/keep-tab/keep-tab.service';
import { WorkPackageIdDisplayField } from 'core-app/shared/components/fields/display/field-types/wp-id-display-field.module';
import { UiStateLinkBuilder } from '../builders/ui-state-link-builder';

export interface IdCellPresentation {
  readonly text:string;
  readonly title:string|null;
  readonly label:string|null;
  readonly required:boolean;
  readonly href:string|null;
}

export class IdCellPresenter {
  private readonly schemaCache = this.injector.get(SchemaCacheService);
  private readonly field = new WorkPackageIdDisplayField('id', { injector: this.injector, container: 'table', options: { tabbable: false } });
  private readonly links = new UiStateLinkBuilder(
    this.injector.get(KeepTabService),
    this.injector.get(CurrentProjectService),
    this.injector.get(PathHelperService),
    this.injector.get(UrlParamsService),
  );

  constructor(private readonly injector:Injector) {}

  public present(workPackage:WorkPackageResource):IdCellPresentation {
    const schema = this.schemaCache.of(workPackage).ofProperty('id');
    if (!schema) return { text: '', title: null, label: null, required: false, href: null };

    const { field } = this;
    field.apply(workPackage, schema);
    const text = field.value ? field.valueString : '';
    return {
      text,
      title: field.title === '' ? null : field.title,
      label: `${field.displayName} ${field.valueString}`,
      required: field.required,
      href: field.value ? this.links.hrefFor(workPackage.id!, 'show', field.valueString) : null,
    };
  }
}

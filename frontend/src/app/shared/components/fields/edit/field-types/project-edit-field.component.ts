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

import { ChangeDetectionStrategy, Component, OnInit, ViewEncapsulation, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { from } from 'rxjs';
import {
  AutocompleterEditFieldComponent,
} from 'core-app/shared/components/fields/edit/field-types/autocompleter-edit-field.component';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { HalResourceService } from 'core-app/features/hal/services/hal-resource.service';
import { take, tap } from 'rxjs/operators';
import isNewResource from 'core-app/features/hal/helpers/is-new-resource';
import idFromLink from 'core-app/features/hal/helpers/id-from-link';
import { CallableHalLink } from 'core-app/features/hal/hal-link/hal-link';
import { IAPIFilter } from 'core-app/shared/components/autocompleter/op-autocompleter/typings';
import { FilterOperator } from 'core-app/shared/helpers/api-v3/api-v3-filter-builder';
import {
  ProjectSelection,
  createProjectSelectionAdapter,
  projectSelectionToResource,
} from 'core-app/shared/components/autocompleter/selection/project-selection';

const unloaded = Symbol('unloaded');

@Component({
  templateUrl: './project-edit-field.component.html',
  styleUrls: ['./project-edit-field.component.sass'],
  encapsulation: ViewEncapsulation.None,
  changeDetection: ChangeDetectionStrategy.OnPush,
  standalone: false,
})
export class ProjectEditFieldComponent extends AutocompleterEditFieldComponent implements OnInit {
  readonly apiV3Service = inject(ApiV3Service);
  readonly http = inject(HttpClient);
  readonly halResourceService = inject(HalResourceService);

  readonly selection = createProjectSelectionAdapter();

  isNew = isNewResource(this.resource);

  url:string;

  private loadedValue:unknown = unloaded;

  ngOnInit():void {
    this.selection.changes$
      .pipe(this.untilDestroyed())
      .subscribe((value) => this.onSelectionChange(value));

    this.selection.stateChanges$
      .pipe(this.untilDestroyed())
      .subscribe(() => this.cdRef.markForCheck());

    super.ngOnInit();
  }

  initialize():void {
    if (this.value !== this.loadedValue) {
      this.loadedValue = this.value;
      this.selection.bridge.load(this.value);
    }

    if (this.schema.allowedValues) {
      this.setUrl();
    } else {
      this.loadFormAndSetUrl();
    }
  }

  onSelectionChange(value:ProjectSelection):void {
    this.value = projectSelectionToResource(value, {
      halResourceService: this.halResourceService,
      apiV3Service: this.apiV3Service,
    });
    this.loadedValue = this.value;

    void this.handler.handleUserSubmit();
  }

  public get APIFilters():IAPIFilter[] {
    const filters = [
        { name: 'active', operator: '=' as FilterOperator, values: ['t'] },
    ];

    const type = this.change.value<{ href:string }|null>('type');
    if (isNewResource(this.resource) && type) {
      const typeId = idFromLink(type.href);
      filters.push({ name: 'type_id', operator: '=', values: [typeId] });
    }

    return filters;
  }

  private loadFormAndSetUrl():void {
    from(this.change.getForm())
      .pipe(
        tap(() => this.setUrl()),
        take(1),
      ).subscribe();
  }

  private setUrl():void {
    this.url = (this.schema.allowedValues as CallableHalLink).$link.href!;
  }
}

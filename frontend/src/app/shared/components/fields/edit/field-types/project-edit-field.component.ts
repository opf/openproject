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
//++

import { ChangeDetectionStrategy, Component, OnInit, ViewEncapsulation, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { from } from 'rxjs';
import {
  EditFieldComponent,
} from 'core-app/shared/components/fields/edit/edit-field.component';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { IProject } from 'core-app/core/state/projects/project.model';
import { HalResourceService } from 'core-app/features/hal/services/hal-resource.service';
import { take, tap } from 'rxjs/operators';
import isNewResource from 'core-app/features/hal/helpers/is-new-resource';
import idFromLink from 'core-app/features/hal/helpers/id-from-link';
import { IAPIFilter } from 'core-app/shared/components/autocompleter/op-autocompleter/typings';
import { FilterOperator } from 'core-app/shared/helpers/api-v3/api-v3-filter-builder';

@Component({
  templateUrl: './project-edit-field.component.html',
  styleUrls: ['./project-edit-field.component.sass'],
  encapsulation: ViewEncapsulation.None,
  changeDetection: ChangeDetectionStrategy.OnPush,
  standalone: false,
})
export class ProjectEditFieldComponent extends EditFieldComponent implements OnInit {
  readonly apiV3Service = inject(ApiV3Service);
  readonly http = inject(HttpClient);
  readonly halResourceService = inject(HalResourceService);

  isNew = isNewResource(this.resource as { id:string | null });

  url:string;

  initialize():void {
    if (this.schema.allowedValues) {
      this.setUrl();
    } else {
      this.loadFormAndSetUrl();
    }
  }

  public onModelChange(project?:IProject):unknown {
    if (project) {
      // We fake a HalResource here because we're using a plain JS object, but the schema loading and editing
      // is part of the older HalResource stack
      const newProject = { ...project };
      const fakeProjectHal = this.halResourceService.createHalResourceOfType('project', newProject);
      this.value = fakeProjectHal;
    } else {
      this.value = null;
    }

    return this.handler.handleUserSubmit();
  }

  public get APIFilters():IAPIFilter[] {
    const filters = [
        { name: 'active', operator: '=' as FilterOperator, values: ['t'] },
    ];

    const type = this.change.value<{ href:string }|null>('type');
    if (isNewResource(this.resource as { id:string | null }) && type) {
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
    // eslint-disable-next-line @typescript-eslint/no-unsafe-member-access
    this.url = this.schema.allowedValues.$link.href as string;
  }
}

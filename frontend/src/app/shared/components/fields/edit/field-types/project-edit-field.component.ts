// -- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2022 the OpenProject GmbH
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

import {
  ChangeDetectorRef,
  Component,
  ElementRef,
  Injector,
  OnInit,
  ViewChild,
  Inject,
} from '@angular/core';
import { NgSelectComponent } from '@ng-select/ng-select';
import { HttpClient } from '@angular/common/http';
import { Subject } from 'rxjs';
import { ID } from '@datorama/akita';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import {
  EditFieldComponent,
  OpEditingPortalSchemaToken,
  OpEditingPortalHandlerToken,
  OpEditingPortalChangesetToken
} from 'core-app/shared/components/fields/edit/edit-field.component';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { getPaginatedResults } from 'core-app/core/apiv3/helpers/get-paginated-results';
import {
  ApiV3ListFilter,
  ApiV3ListParameters,
  listParamsString,
} from 'core-app/core/apiv3/paths/apiv3-list-resource.interface';
import { IHALCollection } from 'core-app/core/apiv3/types/hal-collection.type';
import { IProject } from 'core-app/core/state/projects/project.model';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { ResourceChangeset } from '../../changeset/resource-changeset';
import { IFieldSchema } from '../../field.base';
import { EditFieldHandler } from '../editing-portal/edit-field-handler';
import { ProjectResource } from 'core-app/features/hal/resources/project-resource';
import { HalResourceService } from 'core-app/features/hal/services/hal-resource.service';

@Component({
  templateUrl: './project-edit-field.component.html',
})
export class ProjectEditFieldComponent extends EditFieldComponent implements OnInit {
  @ViewChild(NgSelectComponent, { static: true }) public ngSelectComponent:NgSelectComponent;

  constructor(
    readonly I18n:I18nService,
    readonly elementRef:ElementRef,
    @Inject(OpEditingPortalChangesetToken) protected change:ResourceChangeset<HalResource>,
    @Inject(OpEditingPortalSchemaToken) public schema:IFieldSchema,
    @Inject(OpEditingPortalHandlerToken) readonly handler:EditFieldHandler,
    readonly cdRef:ChangeDetectorRef,
    readonly injector:Injector,

    readonly apiV3Service:ApiV3Service,
    readonly http:HttpClient,
    readonly halResourceService:HalResourceService,
  ) {
    super(
      I18n,
      elementRef,
      change,
      schema,
      handler,
      cdRef,
      injector,
    );
  }

  typeahead$ = new Subject<string>();
  projects$ = new Subject<IProject[]>();

  projectId:ID|null = null;

  public ngOnInit() {
    this.projectId = parseInt(this.value.id, 10);
    console.log(this.projectId);
    this.loadAllProjects();
    this.typeahead$.subscribe((searchText:string) => {
      this.loadAllProjects(searchText);
    });
  }

  public onModelChange(project?:IProject) {
    if (project) {
      this.projectId = project.id;

      // We fake a HalResource here because we're using a plain JS object, but the schema loading and editing
      // is part of the older HalResource stack
      const newProject = {
        ...project,
        $links: { ...project._links },
        $link: project._links.self,
      };
      const fakeProjectHal = this.halResourceService.createHalResourceOfType('project', newProject);
      this.value = fakeProjectHal;
    } else {
      this.projectId = null;
      this.value = null;
    }

    return this.handler.handleUserSubmit();
  }

  public loadAllProjects(searchText:string = ''):void {
    getPaginatedResults<IProject>(
      (params) => {
        const collectionURL = listParamsString({ ...this.getParams(searchText), ...params });
        return this.http.get<IHALCollection<IProject>>(this.apiV3Service.projects.path + collectionURL);
      },
    )
      .subscribe((projects) => {
        this.projects$.next(projects);
      });
  }
    
  public getParams(searchText:string = ''):ApiV3ListParameters {
    const filters:ApiV3ListFilter[] = [
      ['active', '=', ['t']],
    ];

    if (searchText) {
      filters.push([
        'name_and_identifier',
        '~',
        [searchText],
      ]);
    }

    return {
      filters,
      pageSize: -1,
      select: [
        'elements/id',
        'elements/identifier',
        'elements/name',
        'elements/self',
        'total',
        'count',
        'pageSize',
      ],
    };
  }
}

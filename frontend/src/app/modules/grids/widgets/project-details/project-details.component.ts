// -- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2020 the OpenProject GmbH
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
// ++

import {
  ChangeDetectionStrategy,
  ChangeDetectorRef,
  Component,
  ElementRef,
  Injector,
  OnInit,
  ViewChild
} from '@angular/core';
import {AbstractWidgetComponent} from "app/modules/grids/widgets/abstract-widget.component";
import {I18nService} from "core-app/modules/common/i18n/i18n.service";
import {ProjectDmService} from "core-app/modules/hal/dm-services/project-dm.service";
import {CurrentProjectService} from "core-components/projects/current-project.service";
import {SchemaResource} from "core-app/modules/hal/resources/schema-resource";
import {ProjectCacheService} from "core-components/projects/project-cache.service";
import {Observable} from "rxjs";
import {ProjectResource} from "core-app/modules/hal/resources/project-resource";
import {HalResourceEditingService} from "core-app/modules/fields/edit/services/hal-resource-editing.service";

@Component({
  templateUrl: './project-details.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
  providers: [
    HalResourceEditingService
  ]
})
export class WidgetProjectDetailsComponent extends AbstractWidgetComponent implements OnInit {
  @ViewChild('contentContainer', { static: true }) readonly contentContainer:ElementRef;

  public customFields:{key:string, label:string}[] = [];
  public project$:Observable<ProjectResource>;

  constructor(protected readonly i18n:I18nService,
              protected readonly injector:Injector,
              protected readonly projectDm:ProjectDmService,
              protected readonly projectCache:ProjectCacheService,
              protected readonly currentProject:CurrentProjectService,
              protected readonly cdRef:ChangeDetectorRef) {
    super(i18n, injector);
  }

  ngOnInit() {
    this.loadAndRender();
    this.project$ = this.projectCache.requireAndStream(this.currentProject.id!);
  }

  public get isEditable() {
    return false;
  }

  private loadAndRender() {
    Promise.all([
        this.loadProjectSchema()
      ])
      .then(([schema]) => {
        this.setCustomFields(schema);
      });
  }

  private loadProjectSchema() {
    return this.projectDm.schema();
  }

  private setCustomFields(schema:SchemaResource) {
    Object.entries(schema).forEach(([key, keySchema]) => {
      if (key.match(/customField\d+/)) {
        this.customFields.push({key: key, label: keySchema.name });
      }
    });

    this.cdRef.detectChanges();
  }
}

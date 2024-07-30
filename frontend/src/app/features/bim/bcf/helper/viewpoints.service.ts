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

import { Injectable, Injector } from '@angular/core';
import { InjectField } from 'core-app/shared/helpers/angular/inject-field.decorator';
import { BcfApiService } from 'core-app/features/bim/bcf/api/bcf-api.service';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { BcfViewpointPaths } from 'core-app/features/bim/bcf/api/viewpoints/bcf-viewpoint.paths';
import { ViewerBridgeService } from 'core-app/features/bim/bcf/bcf-viewer-bridge/viewer-bridge.service';
import { map, switchMap, tap } from 'rxjs/operators';
import { forkJoin, Observable, of } from 'rxjs';
import { BcfTopicResource } from 'core-app/features/bim/bcf/api/topics/bcf-topic.resource';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import idFromLink from 'core-app/features/hal/helpers/id-from-link';
import { BcfViewpointData, CreateBcfViewpointData } from 'core-app/features/bim/bcf/api/bcf-api.model';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';

@Injectable()
export class ViewpointsService {
  topicUUID:string|number|null = null;

  @InjectField() bcfApi:BcfApiService;

  @InjectField() viewerBridge:ViewerBridgeService;

  @InjectField() apiV3Service:ApiV3Service;

  constructor(readonly injector:Injector) { }

  public getViewPointResource(workPackage:WorkPackageResource, index:number):BcfViewpointPaths {
    const viewpointHref = (workPackage.bcfViewpoints as HalResource[])[index].href as string;

    return this.bcfApi.parse<BcfViewpointPaths>(viewpointHref);
  }

  public getViewPoint$(workPackage:WorkPackageResource, index:number):Observable<BcfViewpointData> {
    const viewpointResource = this.getViewPointResource(workPackage, index);

    return forkJoin({
      viewpoint: viewpointResource.get(),
      selection: viewpointResource.selection.get(),
      visibility: viewpointResource.visibility.get(),
    })
      .pipe(
        map(({ viewpoint, selection, visibility }) => {
          const data = viewpoint as BcfViewpointData;
          data.components = {
            coloring: [],
            selection: selection.selection,
            visibility: visibility.visibility,
          };
          return data;
        }),
      );
  }

  public deleteViewPoint$(workPackage:WorkPackageResource, index:number):Observable<void> {
    const viewpointResource = this.getViewPointResource(workPackage, index);

    return viewpointResource
      .delete()
      .pipe(
        // Update the work package to reload the viewpoints
        tap(() => this.apiV3Service.work_packages.id(workPackage).requireAndStream(true)),
      );
  }

  public saveViewpoint$(workPackage:WorkPackageResource, viewpoint?:CreateBcfViewpointData):Observable<CreateBcfViewpointData> {
    const projectLink = (workPackage.project as HalResource).href;
    const wpProjectId = idFromLink(projectLink);
    const topicUUID$ = this.setBcfTopic$(workPackage);
    // Default to the current viewer's viewpoint
    const viewpoint$ = viewpoint
      ? of(viewpoint)
      : this.viewerBridge.getViewpoint$();

    return forkJoin({
      topicUUID: topicUUID$,
      viewpoint: viewpoint$,
    })
      .pipe(
        switchMap((results) => this.bcfApi
          .projects.id(wpProjectId)
          .topics.id(results.topicUUID)
          .viewpoints
          .post(results.viewpoint)),
        // Update the work package to reload the viewpoints
        tap(() => this.apiV3Service.work_packages.id(workPackage).requireAndStream(true)),
      );
  }

  public resetBcfTopic():void {
    this.topicUUID = null;
  }

  public setBcfTopic$(workPackage:WorkPackageResource):Observable<string|number> {
    if (this.topicUUID !== null) {
      return of(this.topicUUID);
    }
    const topicHref = (workPackage.bcfTopic as HalResource)?.href;
    const topicUUID$ = topicHref
      ? of(this.bcfApi.parse<BcfViewpointPaths>(topicHref).id)
      : this.createBcfTopic$(workPackage);

    return topicUUID$.pipe(
      map((topicUUID) => {
        this.topicUUID = topicUUID;
        return this.topicUUID;
      }),
    );
  }

  private createBcfTopic$(workPackage:WorkPackageResource):Observable<string> {
    const wpProjectId = idFromLink(workPackage.project.href);
    const wpPayload = workPackage.convertBCF.payload;

    return this.bcfApi
      .projects.id(wpProjectId)
      .topics
      .post(wpPayload)
      .pipe(
        map((resource:BcfTopicResource) => {
          this.topicUUID = resource.guid;
          return this.topicUUID;
        }),
      );
  }
}

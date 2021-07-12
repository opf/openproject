import { Injectable, Injector } from '@angular/core';
import { InjectField } from 'core-app/shared/helpers/angular/inject-field.decorator';
import { BcfApiService } from 'core-app/features/bim/bcf/api/bcf-api.service';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { BcfViewpointPaths } from 'core-app/features/bim/bcf/api/viewpoints/bcf-viewpoint.paths';
import { ViewerBridgeService } from 'core-app/features/bim/bcf/bcf-viewer-bridge/viewer-bridge.service';
import { map, switchMap, tap } from 'rxjs/operators';
import { forkJoin, Observable, of } from 'rxjs';
import { BcfViewpointInterface } from 'core-app/features/bim/bcf/api/viewpoints/bcf-viewpoint.interface';
import { BcfTopicResource } from 'core-app/features/bim/bcf/api/topics/bcf-topic.resource';
import { APIV3Service } from 'core-app/core/apiv3/api-v3.service';

@Injectable()
export class ViewpointsService {
  topicUUID:string|number;

  @InjectField() bcfApi:BcfApiService;

  @InjectField() viewerBridge:ViewerBridgeService;

  @InjectField() apiV3Service:APIV3Service;

  constructor(readonly injector:Injector) {}

  public getViewPointResource(workPackage:WorkPackageResource, index:number):BcfViewpointPaths {
    const viewpointHref = workPackage.bcfViewpoints[index].href;

    return this.bcfApi.parse<BcfViewpointPaths>(viewpointHref);
  }

  public getViewPoint$(workPackage:WorkPackageResource, index:number):Observable<BcfViewpointInterface> {
    const viewpointResource = this.getViewPointResource(workPackage, index);

    return viewpointResource.get();
  }

  public deleteViewPoint$(workPackage:WorkPackageResource, index:number):Observable<BcfViewpointInterface> {
    const viewpointResource = this.getViewPointResource(workPackage, index);

    return viewpointResource
      .delete()
      .pipe(
        // Update the work package to reload the viewpoints
        tap(() => this.apiV3Service.work_packages.id(workPackage).requireAndStream(true)),
      );
  }

  public saveViewpoint$(workPackage:WorkPackageResource, viewpoint?:BcfViewpointInterface):Observable<BcfViewpointInterface> {
    const wpProjectId = workPackage.project.idFromLink;
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
        tap((results) => this.apiV3Service.work_packages.id(workPackage).requireAndStream(true)),
      );
  }

  public setBcfTopic$(workPackage:WorkPackageResource) {
    if (this.topicUUID) {
      return of(this.topicUUID);
    }
    const topicHref = workPackage.bcfTopic?.href;
    const topicUUID$ = topicHref
      ? of(this.bcfApi.parse<BcfViewpointPaths>(topicHref)!.id)
      : this.createBcfTopic$(workPackage);

    return topicUUID$.pipe(map((topicUUID) => this.topicUUID = topicUUID));
  }

  private createBcfTopic$(workPackage:WorkPackageResource):Observable<string> {
    const wpProjectId = workPackage.project.idFromLink;
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

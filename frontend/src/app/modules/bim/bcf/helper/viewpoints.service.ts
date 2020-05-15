import {Injectable, Injector} from '@angular/core';
import {InjectField} from "core-app/helpers/angular/inject-field.decorator";
import {BcfApiService} from "core-app/modules/bim/bcf/api/bcf-api.service";
import {WorkPackageResource} from "core-app/modules/hal/resources/work-package-resource";
import {BcfViewpointPaths} from "core-app/modules/bim/bcf/api/viewpoints/bcf-viewpoint.paths";
import {ViewerBridgeService} from "core-app/modules/bim/bcf/bcf-viewer-bridge/viewer-bridge.service";
import {switchMap, map} from 'rxjs/operators';
import {of, forkJoin, Observable} from 'rxjs';
import {BcfViewpointInterface} from "core-app/modules/bim/bcf/api/viewpoints/bcf-viewpoint.interface";


@Injectable()
export class ViewpointsService {
  @InjectField() bcfApi:BcfApiService;
  @InjectField() viewerBridge:ViewerBridgeService;

  constructor(readonly injector:Injector) {
    console.log('this.bcfApi: ', this.bcfApi);
  }

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
    
    return viewpointResource.delete();
  }

  public saveCurrentAsViewpoint$(workPackage:WorkPackageResource): Observable<BcfViewpointInterface> {
    const wpProjectId = workPackage.project.idFromLink;
    const topicHref = workPackage.bcfTopic?.href;
    const topicUUID$ = topicHref ?
                        of(this.bcfApi.parse<BcfViewpointPaths>(topicHref)!.id) :
                        this.createBcfTopic$(workPackage);
    
    return forkJoin({
              topicUUID: topicUUID$,
              viewpoint: this.viewerBridge!.getViewpoint$(),
            })
            .pipe(
              switchMap(results => this.bcfApi
                                          .projects.id(wpProjectId)
                                          .topics.id(results.topicUUID as (string | number))
                                          .viewpoints
                                          .post(results.viewpoint))
            );

    /* const viewpoint = await this.viewerBridge!.getViewpoint();     
    const topicUUID = workPackage.bcfTopic?.href ?
                        this.bcfApi.parse<BcfViewpointPaths>(topicHref)!.id :
                        this.createBcfTopic();
    const wpProjectId = workPackage.project.idFromLink;

    return this.bcfApi
                .projects.id(wpProjectId)
                .topics.id(topicUUID)
                .viewpoints
                .post(viewpoint); */
  }

  protected createBcfTopic$(workPackage:WorkPackageResource):Observable<string> {
    const wpProjectId = workPackage.project.idFromLink;
    const wpPayload = workPackage.convertBCF.payload

    return this.bcfApi
                  .projects.id(wpProjectId)
                  .topics
                  .post(wpPayload)
                  .pipe(
                    map((resource: BcfViewpointInterface) => {
                      console.log('Type this: ', resource);
                      return resource.guid;
                    })
                  );
  }
}

import {Component, Injector, Input, OnDestroy, OnInit} from "@angular/core";
import {I18nService} from "core-app/modules/common/i18n/i18n.service";
import {StateService} from "@uirouter/core";
import {WorkPackageResource} from "core-app/modules/hal/resources/work-package-resource";
import {PathHelperService} from "core-app/modules/common/path-helper/path-helper.service";
import { NgxGalleryOptions, NgxGalleryImage, NgxGalleryAnimation } from 'ngx-gallery';
import {HttpClient, HttpHeaders} from "@angular/common/http";
import {CurrentProjectService} from "core-components/projects/current-project.service";
import {BcfPathHelperService} from "core-app/modules/bcf/helper/bcf-path-helper.service";
import {RevitBridgeService} from "core-app/modules/bcf/services/revit-bridge.service";


export type ViewPointOriginal = { uuid:string, snapshot_id:string, snapshot_file_name:string };
export type ViewPoint = { snapshotId:string, snapshotFileName:string, snapshotFullPath:string };

@Component({
  selector: 'bcf-wp-single-view',
  templateUrl: './bcf-wp-single-view.component.html',
  styleUrls: ['./bcf-wp-single-view.component.sass']
})

export class BcfWpSingleViewComponent implements OnInit, OnDestroy {
  @Input() workPackage:WorkPackageResource;

  galleryOptions:NgxGalleryOptions[];
  galleryImages:NgxGalleryImage[];

  private _viewpoints:ViewPoint[];

  public get viewpoints():ViewPoint[] {
    return this._viewpoints;
  }

  public set viewpoints(viewPoints:ViewPoint[]) {
    this._viewpoints = viewPoints;
  }

  public text = {
  };

  constructor(public readonly state:StateService,
              private readonly I18n:I18nService,
              private readonly injector:Injector,
              private readonly pathHelper:PathHelperService,
              readonly currentProject:CurrentProjectService,
              readonly revitBridgeService:RevitBridgeService,
              readonly httpClient:HttpClient) {
  }

  ngOnInit():void {
    this.viewpoints = this.workPackage.bcf.viewpoints.map((vp:ViewPointOriginal):ViewPoint => {
      return {
        snapshotId: vp.snapshot_id,
        snapshotFileName: vp.snapshot_file_name,
        snapshotFullPath: this.pathHelper.attachmentDownloadPath(vp.snapshot_id, vp.snapshot_file_name)
      };
    });

    this.galleryOptions = [
      {
        width: '100%',
        height: '130px',
        thumbnailsColumns: 5,
        imageAnimation: '',
        previewAnimation: false,
        previewCloseOnEsc: true,
        previewKeyboardNavigation: true,
        imageSize: 'contain',
        imageArrowsAutoHide: true,
        image: false,
        thumbnailsArrowsAutoHide: false,
        thumbnailsAutoHide: true,
        thumbnailsMargin: 5,
        thumbnailMargin: 5,
        previewDownload: true,
        arrowPrevIcon: 'icon-arrow-left2',
        arrowNextIcon: 'icon-arrow-right2',
        closeIcon: 'icon-close',
        downloadIcon: 'icon-download',
        previewCloseOnClick: true,
        thumbnailActions: [
          {
            icon: 'icon-modules',
            onClick: this.setViewpoint.bind(this),
            titleText: 'Set viewpoint'
          }
        ],
        actions: [
          {
            icon: 'icon-modules',
            onClick: this.setViewpoint.bind(this),
            titleText: 'Set viewpoint'
          }
        ]
      },
      // max-width 800
      {
        breakpoint: 800,
        width: '100%',
        height: '300px',
        imagePercent: 80,
        thumbnailsPercent: 20,
        thumbnailsMargin: 5,
        thumbnailMargin: 5,
        imageSize: 'contain',
      },
      // max-width 400
      {
        breakpoint: 400,
        height: '200px',
      }
    ];

    this.galleryImages = this.viewpoints.map((vp:ViewPoint) => {
      return {
        small:  vp.snapshotFullPath,
        medium: vp.snapshotFullPath,
        big:    vp.snapshotFullPath,
      };
    });
  }

  public galleryPreviewOpen():void {
    console.log("preview open");
    jQuery('#top-menu')[0].style.zIndex = '10';
  }

  public galleryPreviewClose():void {
    console.log("preview close");
    jQuery('#top-menu')[0].style.zIndex = '';
  }

  ngOnDestroy():void {
    // Nothing to do.
  }

  setViewpoint(event:Event, index:number):void {
    console.log('Set viewpoint for index', index, event);
    let viewpointUuid = this.workPackage.bcf.viewpoints[index]['uuid'];
    console.log('Set viewpoint for UUID', viewpointUuid);

    console.log("handleClick");
    const trackingId = this.revitBridgeService.newTrackingId();

    this.httpClient.get(
      `/api/bcf/2.1/projects/${this.projectIdentifier()}/topics/${this.topicUuid()}/viewpoints/${viewpointUuid}`,
      {
        withCredentials: true,
        responseType: 'json'
      }
    ).subscribe((data) => {
      console.log("Response of posting viewpiont", data);
      this.revitBridgeService.sendMessageToRevit('ShowViewpoint', trackingId, JSON.stringify(data));
    });

  }

  private projectIdentifier():string|null {
    return this.currentProject.identifier;
  }

  private topicUuid():string {
    return this.workPackage.bcf.uuid;
  }

}

import {Component, Input, OnDestroy, OnInit} from "@angular/core";
import {StateService} from "@uirouter/core";
import {WorkPackageResource} from "core-app/modules/hal/resources/work-package-resource";
import {NgxGalleryImage, NgxGalleryOptions} from '@kolkov/ngx-gallery';
import {RevitBridgeService} from "core-app/modules/bcf/services/revit-bridge.service";
import {PathHelperService} from "core-app/modules/common/path-helper/path-helper.service";
import {HalLink} from "core-app/modules/hal/hal-link/hal-link";
import {BcfApiService} from "core-app/modules/bim/bcf/api/bcf-api.service";
import {BcfViewpointPaths} from "core-app/modules/bim/bcf/api/viewpoints/bcf-viewpoint.paths";
import {CurrentProjectService} from "core-components/projects/current-project.service";

export type ViewPointOriginal = { uuid:string, snapshot_id:string, snapshot_file_name:string };
export type ViewPoint = { snapshotId:string, snapshotFileName?:string, snapshotFullPath:string };

@Component({
  selector: 'bcf-wp-single-view',
  templateUrl: './bcf-wp-single-view.component.html',
  styleUrls: ['./bcf-wp-single-view.component.sass']
})
export class BcfWpSingleViewComponent implements OnInit, OnDestroy {
  @Input() workPackage:WorkPackageResource;

  galleryOptions:NgxGalleryOptions[] = [
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
      thumbnailsAutoHide: false,
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

  galleryImages:NgxGalleryImage[];

  viewpoints:string[];

  text = {};

  constructor(readonly state:StateService,
              readonly pathHelper:PathHelperService,
              readonly currentProject:CurrentProjectService,
              readonly bcfApi:BcfApiService,
              readonly revitBridge:RevitBridgeService,
  ) {
  }

  ngOnInit():void {
    this.viewpoints = this.workPackage.bcfViewpoints.map((vp:HalLink) => {
      const viewpointResource = this.bcfApi.parse(vp.href) as BcfViewpointPaths;

      return {
        snapshotId: viewpointResource.id,
        /* snapshotFileName: vp.snapshot_file_name, TODO NEEDED? */
        snapshotFullPath: `${vp.href}/snapshot`
      } as ViewPoint;
    });

    this.galleryImages = this.viewpoints.map(url => {
      return {
        small: url,
        medium: url,
        big: url,
      };
    });
  }

  ngOnDestroy():void {
    // Nothing to do.
  }

  setViewpoint(event:Event, index:number):void {
    console.log('Set viewpoint for index', index, event);
    let viewpointUuid = this.workPackage.bcf.viewpoints[index]['uuid'];
    console.log('Set viewpoint for UUID', viewpointUuid);

    console.log("handleClick");
    const trackingId = this.revitBridge.newTrackingId();

    this.bcfApi
      .projects.id(this.projectIdentifier)
      .topics.id(this.topicUuid)
      .viewpoints
      .post()
      .subscribe((data) => {
        console.log("Response of posting viewpiont", data);
        this.revitBridge.sendMessageToRevit('ShowViewpoint', trackingId, JSON.stringify(data));
      });

  }

  galleryPreviewOpen():void {
    jQuery('#top-menu')[0].style.zIndex = '10';
  }

  galleryPreviewClose():void {
    jQuery('#top-menu')[0].style.zIndex = '';
  }

  private get projectIdentifier():string {
    return this.currentProject.identifier!;
  }

  private get topicUuid():string {
    return this.workPackage.bcf.uuid;
  }
}

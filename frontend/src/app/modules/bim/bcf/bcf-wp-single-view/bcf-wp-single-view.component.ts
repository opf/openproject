import {Component, Input, OnDestroy, OnInit} from "@angular/core";
import {StateService} from "@uirouter/core";
import {WorkPackageResource} from "core-app/modules/hal/resources/work-package-resource";
import {NgxGalleryImage, NgxGalleryOptions} from '@kolkov/ngx-gallery';
import {PathHelperService} from "core-app/modules/common/path-helper/path-helper.service";
import {HalLink} from "core-app/modules/hal/hal-link/hal-link";
import {BcfApiService} from "core-app/modules/bim/bcf/api/bcf-api.service";
import {BcfViewpointPaths} from "core-app/modules/bim/bcf/api/viewpoints/bcf-viewpoint.paths";
import {CurrentProjectService} from "core-components/projects/current-project.service";
import {I18nService} from "core-app/modules/common/i18n/i18n.service";
import {ViewerBridgeService} from "core-app/modules/bim/bcf/bcf-viewer-bridge/viewer-bridge.service";
import {WorkPackageCacheService} from "core-components/work-packages/work-package-cache.service";

export type ViewPoint = { snapshotId:string, snapshotFullPath:string };

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
      height: '400px',

      // Show only one image ("thumbnail")
      // and disable the large image slideshow
      image: false,
      thumbnailsColumns: 1,
      // Ensure thumbnails are ALWAYS shown
      thumbnailsAutoHide: false,

      imageAnimation: '',
      previewAnimation: false,
      previewCloseOnEsc: true,
      previewKeyboardNavigation: true,
      imageSize: 'contain',
      imageArrowsAutoHide: true,
      // thumbnailsArrowsAutoHide: true,
      thumbnailsMargin: 5,
      thumbnailMargin: 5,
      previewDownload: true,
      previewCloseOnClick: true,
      arrowPrevIcon: 'icon-arrow-left2',
      arrowNextIcon: 'icon-arrow-right2',
      closeIcon: 'icon-close',
      downloadIcon: 'icon-download',
      thumbnailActions: [
        {
          icon: 'icon-watched',
          onClick: this.showViewpoint.bind(this),
          titleText: 'Show this viewpoint'
        }
      ],
      actions: [
        {
          icon: 'icon-watched',
          onClick: this.showViewpoint.bind(this),
          titleText: 'Show this viewpoint'
        }
      ]
    },
    // max-width 800
    {
      breakpoint: 800,
      width: '100%',
      height: '600px',
      imagePercent: 80,
      thumbnailsPercent: 20,
      thumbnailsMargin: 20,
      thumbnailMargin: 20
    },
    // max-width 400
    {
      breakpoint: 400,
      height: '200px',
    }
  ];

  galleryImages:NgxGalleryImage[];

  viewpoints:ViewPoint[];

  text = {
    bcf: this.I18n.t('js.bcf.label_bcf'),
    viewpoint: this.I18n.t('js.bcf.viewpoint'),
    add_viewpoint: this.I18n.t('js.bcf.add_viewpoint'),
  };

  constructor(readonly state:StateService,
              readonly pathHelper:PathHelperService,
              readonly currentProject:CurrentProjectService,
              readonly bcfApi:BcfApiService,
              readonly viewerBridge:ViewerBridgeService,
              readonly wpCache:WorkPackageCacheService,
              readonly I18n:I18nService) {
  }

  ngOnInit():void {
    this.viewpoints = (this.workPackage.bcfViewpoints || []).map((vp:HalLink) => {
      const viewpointResource = this.bcfApi.parse(vp.href!) as BcfViewpointPaths;

      return {
        snapshotId: viewpointResource.id,
        snapshotFullPath: `${vp.href}/snapshot`
      } as ViewPoint;
    });

    this.galleryImages = this.viewpoints.map(viewpoint => {
      return {
        small: viewpoint.snapshotFullPath,
        medium: viewpoint.snapshotFullPath,
        big: viewpoint.snapshotFullPath,
      };
    });
  }

  ngOnDestroy():void {
    // Nothing to do.
  }

  showViewpoint(event:Event, index:number) {
    let viewpointHref = this.workPackage.bcfViewpoints[index].href;
    let viewpoint = this.bcfApi.parse(viewpointHref)!;
    let viewpointUuid = viewpoint.id as string;

    this
      .bcfApi
      .projects.id(this.workPackage.project.idFromLink)
      .topics.id(this.topicUUID!)
      .viewpoints.id(viewpointUuid)
      .get()
      .subscribe(data => {
        this.viewerBridge.showViewpoint(data);
      });
  }

  async saveCurrentAsViewpoint() {
    const viewpoint = await this.viewerBridge.getViewpoint();
    const uuid = this.topicUUID || await this.createBcfTopic();

    this.bcfApi
      .projects.id(this.workPackage.project.idFromLink)
      .topics.id(uuid)
      .viewpoints
      .post(viewpoint)
      .subscribe((result) => {
        // Update the work package to reload the viewpoint
        this.wpCache.require(this.workPackage.id!, true);
      });
  }

  galleryPreviewOpen():void {
    jQuery('#top-menu')[0].style.zIndex = '10';
  }

  galleryPreviewClose():void {
    jQuery('#top-menu')[0].style.zIndex = '';
  }

  private get topicUUID():string|null {
    const topicHref:string|undefined = this.workPackage.bcfTopic?.href;

    if (topicHref) {
      return this.bcfApi.parse(topicHref)!.id as string;
    }

    return null;
  }

  private async createBcfTopic():Promise<string> {
    return this.bcfApi
      .projects.id(this.workPackage.project.idFromLink)
      .topics
      .post(this.workPackage.convertBCF.payload)
      .toPromise()
      .then(resource => resource.guid);
  }
}

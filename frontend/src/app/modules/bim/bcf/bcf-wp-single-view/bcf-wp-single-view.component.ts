import {
  AfterViewInit,
  ChangeDetectionStrategy,
  ChangeDetectorRef,
  Component,
  Input,
  OnDestroy,
  ViewChild
} from "@angular/core";
import {StateService} from "@uirouter/core";
import {WorkPackageResource} from "core-app/modules/hal/resources/work-package-resource";
import {NgxGalleryComponent, NgxGalleryImage, NgxGalleryOptions} from '@kolkov/ngx-gallery';
import {PathHelperService} from "core-app/modules/common/path-helper/path-helper.service";
import {HalLink} from "core-app/modules/hal/hal-link/hal-link";
import {BcfApiService} from "core-app/modules/bim/bcf/api/bcf-api.service";
import {BcfViewpointPaths} from "core-app/modules/bim/bcf/api/viewpoints/bcf-viewpoint.paths";
import {CurrentProjectService} from "core-components/projects/current-project.service";
import {I18nService} from "core-app/modules/common/i18n/i18n.service";
import {ViewerBridgeService} from "core-app/modules/bim/bcf/bcf-viewer-bridge/viewer-bridge.service";
import {WorkPackageCacheService} from "core-components/work-packages/work-package-cache.service";
import {UntilDestroyedMixin} from "core-app/helpers/angular/until-destroyed.mixin";
import {NotificationsService} from "core-app/modules/common/notifications/notifications.service";

export type ViewPoint = { snapshotId:string, snapshotFullPath:string };

@Component({
  selector: 'bcf-wp-single-view',
  templateUrl: './bcf-wp-single-view.component.html',
  styleUrls: ['./bcf-wp-single-view.component.sass'],
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class BcfWpSingleViewComponent extends UntilDestroyedMixin implements AfterViewInit, OnDestroy {
  @Input() workPackage:WorkPackageResource;
  @ViewChild(NgxGalleryComponent) gallery:NgxGalleryComponent;

  text = {
    bcf: this.I18n.t('js.bcf.label_bcf'),
    viewpoint: this.I18n.t('js.bcf.viewpoint'),
    add_viewpoint: this.I18n.t('js.bcf.add_viewpoint'),
    show_viewpoint: this.I18n.t('js.bcf.show_viewpoint'),
    delete_viewpoint: this.I18n.t('js.bcf.delete_viewpoint'),
    text_are_you_sure: this.I18n.t('js.text_are_you_sure'),
    notice_successful_create: this.I18n.t('js.notice_successful_create'),
    notice_successful_delete: this.I18n.t('js.notice_successful_delete'),
  };

  actions = [
    {
      icon: 'icon-watched',
      onClick: this.showViewpoint.bind(this),
      titleText: this.text.show_viewpoint
    },
    {
      icon: 'icon-delete',
      onClick: this.deleteViewpoint.bind(this),
      titleText: this.text.delete_viewpoint
    }
  ];

  galleryOptions:NgxGalleryOptions[] = [
    {
      width: '100%',
      height: '400px',

      // Show first thumbnail by default
      startIndex: 0,

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
      thumbnailActions: this.actions,
      actions: this.actions,
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

  galleryImages:NgxGalleryImage[] = [];

  // Currently, this is static. Need observable if this changes over time
  viewerVisible = this.viewerBridge.viewerVisible();

  viewpoints:ViewPoint[] = [];

  constructor(readonly state:StateService,
              readonly pathHelper:PathHelperService,
              readonly currentProject:CurrentProjectService,
              readonly bcfApi:BcfApiService,
              readonly viewerBridge:ViewerBridgeService,
              readonly wpCache:WorkPackageCacheService,
              readonly notifications:NotificationsService,
              readonly cdRef:ChangeDetectorRef,
              readonly I18n:I18nService) {
    super();
  }

  ngAfterViewInit():void {
    this.wpCache
      .observe(this.workPackage.id!)
      .pipe(
        this.untilDestroyed()
      )
      .subscribe(wp => {
        this.workPackage = wp;

        if (wp.bcfViewpoints) {
          this.setViewpoints();
          this.cdRef.detectChanges();
        }
      });
  }

  showViewpoint(event:Event, index:number) {
    this
      .viewpointFromIndex(index)
      .get()
      .subscribe(data => {
        if (this.viewerVisible
        ) {
          this.viewerBridge.showViewpoint(data);
        } else {
          window.location.href = this.pathHelper.bimDetailsPath(
            this.currentProject.identifier!,
            this.workPackage.id!,
            index
          );
        }
      });
  }

  deleteViewpoint(event:Event, index:number) {
    if (!window.confirm(this.text.text_are_you_sure)) {
      return;
    }

    this
      .viewpointFromIndex(index)
      .delete()
      .subscribe(data => {
        // Update the work package to reload the viewpoint
        this.notifications.addSuccess(this.text.notice_successful_delete);
        this.wpCache.require(this.workPackage.id!, true);
        this.gallery.preview.close();
      });
  }

  async saveCurrentAsViewpoint() {
    const viewpoint = await this.viewerBridge!.getViewpoint();
    const uuid = this.topicUUID || await this.createBcfTopic();

    this.bcfApi
      .projects.id(this.workPackage.project.idFromLink)
      .topics.id(uuid)
      .viewpoints
      .post(viewpoint)
      .subscribe((result) => {
        // Update the work package to reload the viewpoint
        this.notifications.addSuccess(this.text.notice_successful_create);
        this.showIndex = this.viewpoints.length;
        this.wpCache.require(this.workPackage.id!, true);
      });
  }

  galleryPreviewOpen():void {
    jQuery('#top-menu').addClass('-no-z-index');
  }

  galleryPreviewClose():void {
    jQuery('#top-menu').removeClass('-no-z-index');
  }

  onGalleryLoaded() {
    setTimeout(() => this.gallery.show(this.showIndex), 250);
  }

  onGalleryChanged(event:{ index:number }) {
    this.showIndex = event.index;
  }

  private set showIndex(value:number) {
    const options = [...this.galleryOptions];
    options[0].startIndex = value;
    this.galleryOptions = options;
  }

  private get showIndex():number {
    return this.galleryOptions[0].startIndex!;
  }

  private get topicUUID():string|null {
    const topicHref:string|undefined = this.workPackage.bcfTopic?.href;

    if (topicHref) {
      return this.bcfApi.parse<BcfViewpointPaths>(topicHref)!.id as string;
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

  private setViewpoints() {
    const length = this.workPackage.bcfViewpoints.length;

    if (this.showIndex < 0 || length < 1) {
      this.showIndex = 0;
    } else if (this.showIndex >= length) {
      this.showIndex = length - 1;
    }

    this.viewpoints = this.workPackage.bcfViewpoints.map((vp:HalLink) => {
      const viewpointResource = this.bcfApi.parse<BcfViewpointPaths>(vp.href!);

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

  private viewpointFromIndex(index:number):BcfViewpointPaths {
    let viewpointHref = this.workPackage.bcfViewpoints[index].href;
    return this.bcfApi.parse<BcfViewpointPaths>(viewpointHref);
  }
}

import { ChangeDetectionStrategy, Component } from "@angular/core";
import { BcfWpAttributeGroupComponent } from "core-app/modules/bim/bcf/bcf-wp-attribute-group/bcf-wp-attribute-group.component";
import { take, switchMap } from "rxjs/operators";
import { WorkPackageResource } from "core-app/modules/hal/resources/work-package-resource";
import { forkJoin } from "rxjs";
import { BcfViewpointInterface } from "core-app/modules/bim/bcf/api/viewpoints/bcf-viewpoint.interface";
import { BcfViewpointItem } from "core-app/modules/bim/bcf/api/viewpoints/bcf-viewpoint-item.interface";


@Component({
  templateUrl: './bcf-wp-attribute-group.component.html',
  styleUrls: ['./bcf-wp-attribute-group.component.sass'],
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class BcfNewWpAttributeGroupComponent extends BcfWpAttributeGroupComponent {
  galleryViewpoints:BcfViewpointItem[] = [];

  ngAfterViewInit():void {
    if (this.viewerVisible) {
      super.ngAfterViewInit();

      // Save any leftover viewpoints when saving the work package
      if (this.workPackage.isNew) {
        this.observeCreation();
      }
    }
  }

  // Because this is a new WorkPackage, in order to save the
  // viewpoints on it we need to:
  // - Wait until the WorkPackage is created
  // - Create the BCFTopic on it to save the viewpoints
  private observeCreation() {
    this.wpCreate
      .onNewWorkPackage()
      .pipe(
        this.untilDestroyed(),
        take(1),
        switchMap((wp:WorkPackageResource) => this.viewpointsService.setBcfTopic$(wp), (wp) => wp),
        switchMap((wp:WorkPackageResource) => {
          this.workPackage = wp;
          const observables = this.galleryViewpoints
            .filter(viewPointItem => !viewPointItem.href && viewPointItem.viewpoint)
            .map(viewPointItem => this.viewpointsService.saveViewpoint$(this.workPackage, viewPointItem.viewpoint));

          return forkJoin(observables);
        })
      )
      .subscribe((viewpoints:BcfViewpointInterface[]) => {
        this.showIndex = this.galleryViewpoints.length - 1;
      });
  }

  // Disable show viewpoint functionality
  showViewpoint(workPackage:WorkPackageResource, index:number) {
    return;
  }

  deleteViewpoint(workPackage:WorkPackageResource, index:number) {
    this.galleryViewpoints = this.galleryViewpoints.filter((_, i) => i !== index);

    this.setViewpointsOnGallery(this.galleryViewpoints);

    return;
  }

  saveViewpoint() {
    this.viewerBridge
      .getViewpoint$()
      .subscribe(viewpoint => {
        const newViewpoint = {
          snapshotURL: viewpoint.snapshot.snapshot_data,
          viewpoint: viewpoint
        };

        this.galleryViewpoints = [
          ...this.galleryViewpoints,
          newViewpoint
        ];

        this.setViewpointsOnGallery(this.galleryViewpoints);

        // Select the last created viewpoint and show it
        this.showIndex = this.galleryViewpoints.length - 1;
        this.selectViewpointInGallery();
      });
  }

  shouldShowGroup() {
    return this.createAllowed && this.viewerVisible;
  }
  protected actions() {
    // Show only delete button
    return super
      .actions()
      .filter(el => el.icon === 'icon-delete');
  }
}

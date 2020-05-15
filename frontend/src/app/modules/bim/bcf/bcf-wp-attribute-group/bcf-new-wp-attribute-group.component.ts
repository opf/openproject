import {ChangeDetectionStrategy, Component} from "@angular/core";
import {BcfWpAttributeGroupComponent} from "core-app/modules/bim/bcf/bcf-wp-attribute-group/bcf-wp-attribute-group.component";
import {take} from "rxjs/operators";
import {WorkPackageResource} from "core-app/modules/hal/resources/work-package-resource";

@Component({
  templateUrl: './bcf-wp-attribute-group.component.html',
  styleUrls: ['./bcf-wp-attribute-group.component.sass'],
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class BcfNewWpAttributeGroupComponent extends BcfWpAttributeGroupComponent {

  ngAfterViewInit():void {
    super.ngAfterViewInit();

    // Save any leftover viewpoints when saving the work package
    if (this.workPackage.isNew) {
      this.observeCreation();
    }
  }

  // Disable show viewpoint functionality
  showViewpoint(workPackage:WorkPackageResource, index:number) {
    return;
  }

  deleteViewpoint(workPackage:WorkPackageResource, index:number) {
    this.setViewpoints(
      this.viewpoints.filter((_, i) => i !== index)
    );
    return;
  }

  async saveCurrentAsViewpoint() {
    const viewpoint = await this.viewerBridge!.getViewpoint();

    this.setViewpoints([
      ...this.viewpoints,
      {
        snapshotURL: viewpoint.snapshot.snapshot_data,
        viewpoint: viewpoint
      }
    ]);

    // Select the last created viewpoint and show it
    this.showIndex = this.viewpoints.length - 1;
    this.selectViewpointInGallery();
  }

  shouldShowGroup() {
    return this.createAllowed && this.viewerVisible;
  }

  private observeCreation() {
    this.wpCreate
      .onNewWorkPackage()
      .pipe(
        this.untilDestroyed(),
        take(1)
      )
      .subscribe(async (wp:WorkPackageResource) => {
        this.workPackage = wp;
        for (let el of this.viewpoints) {
          if (!el.href && el.viewpoint) {
            await this.persistViewpoint(el.viewpoint!);
          }
        }

        this.showIndex = this.viewpoints.length - 1;
        this.wpCache.require(this.workPackage.id!, true);
      });
  }

  protected actions() {
    // Show only delete button
    return super
      .actions()
      .filter(el => el.icon === 'icon-delete');
  }
}
